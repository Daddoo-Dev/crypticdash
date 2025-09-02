#include "windows_store_service.h"
#include <flutter/standard_method_codec.h>
#include <iostream>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

WindowsStoreService::WindowsStoreService() : m_initialized(false) {
}

WindowsStoreService::~WindowsStoreService() {
}

bool WindowsStoreService::Initialize() {
    try {
        if (InitializeStoreContext()) {
            m_initialized = true;
            return true;
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Failed to initialize Windows Store Service: " << e.what() << std::endl;
    }
    return false;
}

bool WindowsStoreService::InitializeStoreContext() {
    try {
        m_storeContext = StoreContext::GetDefault();
        return true;
    }
    catch (const std::exception& e) {
        std::cerr << "Failed to initialize store context: " << e.what() << std::endl;
        return false;
    }
}

bool WindowsStoreService::PurchaseProduct(const std::string& productId) {
    if (!m_initialized) {
        std::cerr << "Windows Store Service not initialized" << std::endl;
        return false;
    }

    try {
        // Convert string to wstring for WinRT
        std::wstring wProductId(productId.begin(), productId.end());
        
        // Get the product
        auto product = m_storeContext.GetStoreProductForCurrentAppAsync().get();
        
        if (product) {
            // Request purchase
            auto result = product.RequestProductPurchaseAsync().get();
            
            if (result.Status() == StorePurchaseStatus::Succeeded) {
                std::cout << "Purchase successful for product: " << productId << std::endl;
                return true;
            }
            else {
                std::cerr << "Purchase failed with status: " << static_cast<int>(result.Status()) << std::endl;
                return false;
            }
        }
        else {
            std::cerr << "Product not found: " << productId << std::endl;
            return false;
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Purchase error: " << e.what() << std::endl;
        return false;
    }
}

bool WindowsStoreService::HasActiveSubscription(const std::string& productId) {
    if (!m_initialized) {
        return false;
    }

    try {
        // Get license information
        auto license = m_storeContext.GetAppLicenseAsync().get();
        
        if (license) {
            // Check if user has active license
            return license.IsActive();
        }
        
        return false;
    }
    catch (const std::exception& e) {
        std::cerr << "Error checking subscription: " << e.what() << std::endl;
        return false;
    }
}

bool WindowsStoreService::RestorePurchases() {
    if (!m_initialized) {
        return false;
    }

    try {
        // Request license refresh
        auto result = m_storeContext.GetAppLicenseAsync().get();
        
        if (result) {
            std::cout << "Purchases restored successfully" << std::endl;
            return true;
        }
        
        return false;
    }
    catch (const std::exception& e) {
        std::cerr << "Error restoring purchases: " << e.what() << std::endl;
        return false;
    }
}

std::string WindowsStoreService::GetProductDetails(const std::string& productId) {
    if (!m_initialized) {
        return "{}";
    }

    try {
        // Get product information
        auto product = m_storeContext.GetStoreProductForCurrentAppAsync().get();
        
        if (product) {
            json productDetails;
            productDetails["id"] = productId;
            productDetails["title"] = GetProductTitle(product);
            productDetails["description"] = GetProductDescription(product);
            productDetails["price"] = GetProductPrice(product);
            productDetails["currencyCode"] = "USD"; // Default for Windows Store
            
            return productDetails.dump();
        }
        
        return "{}";
    }
    catch (const std::exception& e) {
        std::cerr << "Error getting product details: " << e.what() << std::endl;
        return "{}";
    }
}

std::string WindowsStoreService::GetProductPrice(const StoreProduct& product) {
    try {
        auto price = product.Price();
        if (price) {
            return winrt::to_string(price.FormattedPrice());
        }
        return "$9.99";
    }
    catch (...) {
        return "$9.99";
    }
}

std::string WindowsStoreService::GetProductDescription(const StoreProduct& product) {
    try {
        auto description = product.Description();
        if (description) {
            return winrt::to_string(description);
        }
        return "Annual subscription for Cryptic Dash";
    }
    catch (...) {
        return "Annual subscription for Cryptic Dash";
    }
}

std::string WindowsStoreService::GetProductTitle(const StoreProduct& product) {
    try {
        auto title = product.Title();
        if (title) {
            return winrt::to_string(title);
        }
        return "Premium Subscription";
    }
    catch (...) {
        return "Premium Subscription";
    }
}
