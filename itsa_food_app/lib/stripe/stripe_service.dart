import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:itsa_food_app/stripe/const.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  // This method now returns a Map with the payment status and message
  Future<Map<String, dynamic>> makePayment() async {
    try {
      print("Step 1: Creating payment intent...");

      // Step 1: Create a payment intent with a predefined amount and currency
      String? paymentIntentClientSecret = await _createPaymentIntent(
        100, // Amount (in cents)
        "usd", // Currency
      );

      if (paymentIntentClientSecret == null) {
        // Return failure if the payment intent creation failed
        print("Payment intent creation failed.");
        return {
          'status': 'failed',
          'message': 'Failed to create payment intent'
        };
      }

      print("Payment intent created successfully: $paymentIntentClientSecret");

      // Step 2: Initialize the payment sheet with the client secret
      print("Step 2: Initializing payment sheet...");
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "ITSA Superapp",
        ),
      );

      print("Payment sheet initialized successfully.");

      // Step 3: Process the payment and return the result
      return await _processPayment();
    } catch (e) {
      print("Error in makePayment: $e");
      return {'status': 'failed', 'message': e.toString()};
    }
  }

  // Create a payment intent to initiate the payment process
  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      print(
          "Step 1: Sending request to Stripe API to create payment intent...");

      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
      };

      // Step 1: Make a POST request to the Stripe API to create the payment intent
      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $stripeSecretKey",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.data != null && response.data["client_secret"] != null) {
        print(
            "Payment intent created successfully: ${response.data["client_secret"]}");
        return response.data["client_secret"];
      } else {
        print("Error: No client secret returned in the response.");
        return null;
      }
    } catch (e) {
      print("Error in _createPaymentIntent: $e");
      return null;
    }
  }

  // Process the payment through the Stripe payment sheet
  Future<Map<String, dynamic>> _processPayment() async {
    try {
      print("Step 1: Presenting the payment sheet...");

      // Step 1: Present the payment sheet to the user
      await Stripe.instance.presentPaymentSheet();
      // We only call confirmPaymentSheetPayment after the payment sheet is presented
      await Stripe.instance.confirmPaymentSheetPayment();

      print("Payment confirmed successfully.");
      // Return success if payment is processed without error
      return {'status': 'succeeded', 'message': 'Payment succeeded'};
    } catch (e) {
      print("Error in _processPayment: $e");
      // Return failed status if an error occurs during payment confirmation
      return {'status': 'failed', 'message': e.toString()};
    }
  }

  // Helper function to calculate the amount (converting to cents)
  String _calculateAmount(int amount) {
    final calculatedAmount = amount * 100; // Stripe works with cents
    print("Calculated amount in cents: $calculatedAmount");
    return calculatedAmount.toString();
  }
}
