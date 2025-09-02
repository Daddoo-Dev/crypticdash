#include "windows_store_service.h"
#include <iostream>
#include <sstream>

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
        return m_storeContext != nullptr;
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
        // For now, return false as we need to implement proper purchase flow
        // This will be implemented when we have the actual product in the Store
        std::cout << "Purchase requested for product: " << productId << std::endl;
        return false;
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
        // For now, return false as we need to implement proper license checking
        // This will be implemented when we have the actual product in the Store
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
        // For now, return false as we need to implement proper restore
        // This will be implemented when we have the actual product in the Store
        std::cout << "Restore purchases requested" << std::endl;
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
        // Return default product details for now
        std::stringstream json;
        json << "{";
        json << "\"id\":\"" << productId << "\",";
        json << "\"title\":\"Premium Subscription\",";
        json << "\"description\":\"Annual subscription for Cryptic Dash\",";
        json << "\"price\":\"$9.99\",";
        json << "\"currencyCode\":\"USD\"";
        json << "}";
        
        return json.str();
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

std::string WindowsStoreService::EscapeJsonString(const std::string& input) {
    std::string result;
    result.reserve(input.length());
    
    for (char c : input) {
        switch (c) {
            case '"': result += "\\\""; break;
            case '\\': result += "\\\\"; break;
            case '\b': result += "\\b"; break;
            case '\f': result += "\\f"; break;
            case '\n': result += "\\n"; break;
            case '\r': result += "\\r"; break;
            case '\t': result += "\\t"; break;
            default: result += c; break;
        }
    }
    
    return result;
}
