#ifndef WINDOWS_STORE_SERVICE_H
#define WINDOWS_STORE_SERVICE_H

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>
#include <memory>
#include <string>

// Microsoft Store Services SDK includes
#include <winrt/Windows.Services.Store.h>
#include <winrt/Windows.Foundation.h>

using namespace winrt;
using namespace Windows::Services::Store;
using namespace Windows::Foundation;

class WindowsStoreService {
public:
    WindowsStoreService();
    ~WindowsStoreService();

    // Initialize the store service
    bool Initialize();

    // Purchase a product
    bool PurchaseProduct(const std::string& productId);

    // Check if user has active subscription
    bool HasActiveSubscription(const std::string& productId);

    // Restore purchases
    bool RestorePurchases();

    // Get product details
    std::string GetProductDetails(const std::string& productId);

private:
    StoreContext m_storeContext;
    bool m_initialized;

    // Helper methods
    bool InitializeStoreContext();
    std::string GetProductPrice(const StoreProduct& product);
    std::string GetProductDescription(const StoreProduct& product);
    std::string GetProductTitle(const StoreProduct& product);
};

#endif // WINDOWS_STORE_SERVICE_H
