#include "windows_store_service.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>

namespace {

class WindowsStoreServicePlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

    WindowsStoreServicePlugin();

    virtual ~WindowsStoreServicePlugin();

private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    // Method channel for communicating with Flutter
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

    // Windows Store Service instance
    std::unique_ptr<WindowsStoreService> store_service_;
};

// static
void WindowsStoreServicePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "windows_store_service",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<WindowsStoreServicePlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

WindowsStoreServicePlugin::WindowsStoreServicePlugin() {
    // Initialize the Windows Store Service
    store_service_ = std::make_unique<WindowsStoreService>();
    if (!store_service_->Initialize()) {
        std::cerr << "Failed to initialize Windows Store Service" << std::endl;
    }
}

WindowsStoreServicePlugin::~WindowsStoreServicePlugin() {}

void WindowsStoreServicePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const std::string& method_name = method_call.method_name();

    if (method_name == "purchaseProduct") {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            auto product_id_it = arguments->find(flutter::EncodableValue("productId"));
            if (product_id_it != arguments->end()) {
                const std::string& product_id = std::get<std::string>(product_id_it->second);
                bool success = store_service_->PurchaseProduct(product_id);
                result->Success(flutter::EncodableValue(success));
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Missing productId parameter");
    }
    else if (method_name == "hasActiveSubscription") {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            auto product_id_it = arguments->find(flutter::EncodableValue("productId"));
            if (product_id_it != arguments->end()) {
                const std::string& product_id = std::get<std::string>(product_id_it->second);
                bool has_subscription = store_service_->HasActiveSubscription(product_id);
                result->Success(flutter::EncodableValue(has_subscription));
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Missing productId parameter");
    }
    else if (method_name == "restorePurchases") {
        bool success = store_service_->RestorePurchases();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method_name == "getProductDetails") {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            auto product_id_it = arguments->find(flutter::EncodableValue("productId"));
            if (product_id_it != arguments->end()) {
                const std::string& product_id = std::get<std::string>(product_id_it->second);
                std::string details = store_service_->GetProductDetails(product_id);
                result->Success(flutter::EncodableValue(details));
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Missing productId parameter");
    }
    else {
        result->NotImplemented();
    }
}

}  // namespace

void WindowsStoreServicePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
    WindowsStoreServicePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
