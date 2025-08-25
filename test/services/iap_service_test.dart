import 'package:flutter_test/flutter_test.dart';
import 'package:crypticdash/services/iap_service.dart';
import 'package:crypticdash/services/platform_iap_services.dart';

void main() {
  setUpAll(() {
    // Initialize Flutter bindings for testing
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('IAPService', () {
    late IAPService iapService;

    setUp(() {
      iapService = IAPService();
    });

    test('initializes with free subscription status', () {
      expect(iapService.subscriptionStatus, equals(SubscriptionStatus.free));
      expect(iapService.isPremiumActive, isFalse);
      expect(iapService.isInTrialPeriod, isTrue); // New users start with trial
    });

    test('trial start date is set on initialization', () {
      expect(iapService.trialStartDate, isNotNull);
      expect(iapService.trialStartDate!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('trial days remaining calculation', () {
      final daysRemaining = iapService.getTrialDaysRemaining();
      expect(daysRemaining, greaterThan(0));
      expect(daysRemaining, lessThanOrEqualTo(30));
    });

    test('subscription info provides correct data', () {
      final info = iapService.getSubscriptionInfo();
      expect(info.status, equals(SubscriptionStatus.free));
      expect(info.isInTrial, isTrue);
      expect(info.productId, equals('crypticdash_premium_yearly'));
      expect(info.price, equals('\$9.99/year'));
    });

    test('can add repositories based on trial status', () {
      final info = iapService.getSubscriptionInfo();
      expect(info.maxRepositories, equals(3)); // Trial users get 3 repos
      expect(info.canAddRepositories, isTrue);
    });
  });

  group('SubscriptionInfo', () {
    test('free tier repository limits', () {
      const info = SubscriptionInfo(
        status: SubscriptionStatus.free,
        isInTrial: false,
        trialDaysRemaining: 0,
        productId: 'test',
        price: '\$9.99',
      );
      
      expect(info.maxRepositories, equals(1));
      expect(info.canAddRepositories, isFalse);
    });

    test('trial tier repository limits', () {
      const info = SubscriptionInfo(
        status: SubscriptionStatus.free,
        isInTrial: true,
        trialDaysRemaining: 15,
        productId: 'test',
        price: '\$9.99',
      );
      
      expect(info.maxRepositories, equals(3));
      expect(info.canAddRepositories, isTrue);
    });

    test('premium tier repository limits', () {
      const info = SubscriptionInfo(
        status: SubscriptionStatus.premium,
        isInTrial: false,
        trialDaysRemaining: 0,
        productId: 'test',
        price: '\$9.99',
      );
      
      expect(info.maxRepositories, equals(-1)); // Unlimited
      expect(info.canAddRepositories, isTrue);
    });
  });

  group('PlatformIAPService implementations', () {
    test('MockStoreService provides test data', () async {
      final mockService = MockStoreService();
      
      final productDetails = await mockService.getProductDetails('test_product');
      expect(productDetails, isNotNull);
      expect(productDetails!.id, equals('crypticdash_premium_yearly'));
      expect(productDetails.title, contains('Mock'));
      
      final hasSubscription = await mockService.hasActiveSubscription('test_product');
      expect(hasSubscription, isFalse);
      
      final purchaseResult = await mockService.purchaseProduct('test_product');
      expect(purchaseResult, isTrue);
      
      final restoreResult = await mockService.restorePurchases();
      expect(restoreResult, isTrue);
    });

    test('MockStoreService can be disposed', () {
      final mockService = MockStoreService();
      expect(() => mockService.dispose(), returnsNormally);
    });
  });
}
