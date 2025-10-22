library apartmenta;

import 'package:collection/collection.dart'; // For lastOrNull
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zarinpal/zarinpal.dart'; // Import the Zarinpal package (assumed)

// Models
enum UserRole { admin, owner, resident }

class User {
  String id;
  String name;
  UserRole role;
  String? contactInfo;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.contactInfo,
  });
}

class Building {
  String id;
  String name;
  List<Unit> units;
  Fund fund;

  Building({
    required this.id,
    required this.name,
    required this.units,
    required this.fund,
  });
}

class Unit {
  String id;
  String ownerName;
  double area;
  int residents;
  int parkingSlots;
  double balance;
  String? contactInfo;

  Unit({
    required this.id,
    required this.ownerName,
    this.area = 0.0,
    this.residents = 0,
    this.parkingSlots = 0,
    this.balance = 0.0,
    this.contactInfo,
  });
}

class Cost {
  String id;
  String description;
  double amount;
  DateTime date;
  bool isApproved;
  String? proposedBy;
  String? approvedBy;

  Cost({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.isApproved = false,
    this.proposedBy,
    this.approvedBy,
  });
}

class Fund {
  String id;
  double balance;
  List<Cost> costs;
  List<Payment> payments;

  Fund({
    required this.id,
    this.balance = 0.0,
    this.costs = const [],
    this.payments = const [],
  });
}

enum ChargeType { perArea, perResident, perParking }

class Charge {
  String id;
  Unit unit;
  double amount;
  ChargeType type;
  DateTime date;
  bool isPaid;

  Charge({
    required this.id,
    required this.unit,
    required this.amount,
    required this.type,
    required this.date,
    this.isPaid = false,
  });
}

enum PaymentMethod { online, cash, cardToCard, prePayment }

class Payment {
  String id;
  Unit unit;
  double amount;
  PaymentMethod method;
  DateTime date;

  Payment({
    required this.id,
    required this.unit,
    required this.amount,
    required this.method,
    required this.date,
  });
}

class AuditLog {
  String id;
  String action;
  String userId;
  DateTime timestamp;
  String details;

  AuditLog({
    required this.id,
    required this.action,
    required this.userId,
    required this.timestamp,
    required this.details,
  });
}

// Services
class CostService {
  List<Cost> costs = [];

  void addCost(Cost cost) {
    if (!cost.isApproved) {
      throw Exception('هزینه ${cost.id} هنوز تأیید نشده است.');
    }
    costs.add(cost);
  }

  List<Cost> getCosts() => costs;

  void addBulkCosts(List<Cost> costs) {
    for (var cost in costs) {
      addCost(cost);
    }
  }

  void proposeCost(Cost cost, String userId) {
    cost.proposedBy = userId;
    costs.add(cost);
  }

  bool approveCost(String costId, String approverId) {
    final cost = costs.firstWhere(
      (c) => c.id == costId,
      orElse: () => throw Exception('هزینه $costId یافت نشد.'),
    );
    if (!cost.isApproved) {
      cost.isApproved = true;
      cost.approvedBy = approverId;
      return true;
    }
    return false;
  }

  List<Cost> getPendingCosts() => costs.where((c) => !c.isApproved).toList();
}

class FundService {
  Fund fund;

  FundService(this.fund);

  void addCost(Cost cost) {
    if (!cost.isApproved) {
      throw Exception('هزینه ${cost.id} هنوز تأیید نشده است.');
    }
    fund.costs.add(cost);
    fund.balance -= cost.amount;
  }

  void addPayment(Payment payment) {
    fund.payments.add(payment);
    fund.balance += payment.amount;
  }

  double getBalance() => fund.balance;

  String getTransactionHistory() {
    String history = 'تاریخچه تراکنش‌های صندوق ${fund.id}:\n';
    history += '----------------------------------------\n';
    history += 'هزینه‌ها:\n';
    for (var cost in fund.costs) {
      history += '- ${cost.date.toString().substring(0, 10)}: ${cost.description}, ${cost.amount}\n';
    }
    history += '\nپرداخت‌ها:\n';
    for (var payment in fund.payments) {
      history += '- ${payment.date.toString().substring(0, 10)}: واحد ${payment.unit.id}, ${payment.amount} (${payment.method})\n';
    }
    return history;
  }
}

class ChargeService {
  List<Charge> charges = [];

  void calculateCharge(Unit unit, ChargeType type, double rate) {
    double amount;
    switch (type) {
      case ChargeType.perArea:
        amount = unit.area * rate;
        break;
      case ChargeType.perResident:
        amount = unit.residents * rate;
        break;
      case ChargeType.perParking:
        amount = unit.parkingSlots * rate;
        break;
    }
    charges.add(Charge(
      id: DateTime.now().toString(),
      unit: unit,
      amount: amount,
      type: type,
      date: DateTime.now(),
    ));
  }

  void notifyResidents(List<Charge> charges) {
    // TODO: Integrate with a real notification service (e.g., Firebase Cloud Messaging)
    for (var charge in charges) {
      if (charge.unit.contactInfo != null) {
        debugPrint('شارژ ${charge.amount} برای واحد ${charge.unit.id} به ${charge.unit.contactInfo} ارسال شد.');
      } else {
        debugPrint('شارژ ${charge.amount} برای واحد ${charge.unit.id} ارسال شد (بدون اطلاعات تماس).');
      }
    }
  }

  void notifyOwnersOnly(List<Charge> charges) {
    // TODO: Integrate with a real notification service
    for (var charge in charges) {
      if (charge.unit.contactInfo != null) {
        debugPrint('شارژ ${charge.amount} برای مالک واحد ${charge.unit.id} (${charge.unit.ownerName}) به ${charge.unit.contactInfo} ارسال شد.');
      } else {
        debugPrint('شارژ ${charge.amount} برای مالک واحد ${charge.unit.id} (${charge.unit.ownerName}) ارسال شد (بدون اطلاعات تماس).');
      }
    }
  }

  List<Charge> getChargesForUnit(Unit unit) =>
      charges.where((charge) => charge.unit.id == unit.id).toList();

  List<Charge> getUnpaidCharges(Unit unit) =>
      charges.where((charge) => charge.unit.id == unit.id && !charge.isPaid).toList();

  void calculateRecurringCharges(List<Unit> units, ChargeType type, double rate, {int frequencyDays = 30}) {
    for (var unit in units) {
      final lastCharge = charges
          .where((charge) => charge.unit.id == unit.id && charge.type == type)
          .toList()
          .lastOrNull;
      if (lastCharge == null ||
          DateTime.now().difference(lastCharge.date).inDays >= frequencyDays) {
        calculateCharge(unit, type, rate);
      }
    }
  }

  void sendPaymentReminders(List<Unit> units) {
    // TODO: Integrate with a real notification service
    for (var unit in units) {
      final unpaidCharges = getUnpaidCharges(unit);
      if (unpaidCharges.isNotEmpty) {
        final totalUnpaid = unpaidCharges.fold(0.0, (sum, charge) => sum + charge.amount);
        if (unit.contactInfo != null) {
          debugPrint('یادآوری پرداخت برای واحد ${unit.id}: بدهی $totalUnpaid به ${unit.contactInfo} ارسال شد.');
        } else {
          debugPrint('یادآوری پرداخت برای واحد ${unit.id}: بدهی $totalUnpaid (بدون اطلاعات تماس).');
        }
      }
    }
  }
}

class PaymentService {
  List<Payment> payments = [];
  final String merchantId = 'YOUR_ZARINPAL_MERCHANT_ID'; // Replace with actual merchant ID
  final Zarinpal zarinpal = Zarinpal(); // Configure with actual Zarinpal package

  void processPayment(Unit unit, double amount, PaymentMethod method) {
    if (amount <= 0) {
      throw Exception('مبلغ پرداخت باید مثبت باشد.');
    }
    final payment = Payment(
      id: DateTime.now().toString(),
      unit: unit,
      amount: amount,
      method: method,
      date: DateTime.now(),
    );
    payments.add(payment);
    unit.balance += amount;
  }

  Future<bool> processOnlinePayment(Unit unit, double amount) async {
    try {
      final paymentRequest = PaymentRequest(
        merchantId: merchantId,
        amount: (amount * 10).toInt(),
        description: 'پرداخت شارژ واحد ${unit.id}',
        callbackUrl: 'yourapp://payment/callback',
      );

      final response = await zarinpal.requestPayment(paymentRequest);

      if (response.status == 100) {
        await zarinpal.startPayment(response.authority);
        final verificationResponse = await zarinpal.verifyPayment(
          authority: response.authority,
          amount: (amount * 10).toInt(),
        );

        if (verificationResponse.status == 100) {
          processPayment(unit, amount, PaymentMethod.online);
          debugPrint('پرداخت آنلاین ${amount} برای واحد ${unit.id} با موفقیت انجام شد.');
          return true;
        } else {
          debugPrint('خطا در تأیید پرداخت: ${verificationResponse.status}');
          return false;
        }
      } else {
        debugPrint('خطا در درخواست پرداخت: ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('خطا در پردازش پرداخت آنلاین: $e');
      return false;
    }
  }

  Future<String?> generatePaymentLink(Unit unit, double amount) async {
    try {
      final paymentRequest = PaymentRequest(
        merchantId: merchantId,
        amount: (amount * 10).toInt(),
        description: 'پرداخت شارژ واحد ${unit.id}',
        callbackUrl: 'yourapp://payment/callback',
      );

      final response = await zarinpal.requestPayment(paymentRequest);

      if (response.status == 100) {
        final paymentUrl = 'https://www.zarinpal.com/pg/StartPay/${response.authority}';
        debugPrint('لینک پرداخت برای واحد ${unit.id}: $paymentUrl');
        return paymentUrl;
      } else {
        debugPrint('خطا در ایجاد لینک پرداخت: ${response.status}');
        return null;
      }
    } catch (e) {
      debugPrint('خطا در ایجاد لینک پرداخت: $e');
      return null;
    }
  }

  void processCashPayment(Unit unit, double amount) {
    processPayment(unit, amount, PaymentMethod.cash);
    debugPrint('پرداخت نقدی ${amount} برای واحد ${unit.id} ثبت شد.');
  }

  void processCardToCardPayment(Unit unit, double amount) {
    processPayment(unit, amount, PaymentMethod.cardToCard);
    debugPrint('پرداخت کارت به کارت ${amount} برای واحد ${unit.id} ثبت شد.');
  }

  void processPrePayment(Unit unit, double amount) {
    processPayment(unit, amount, PaymentMethod.prePayment);
    debugPrint('پیش‌پرداخت ${amount} برای واحد ${unit.id} ثبت شد.');
  }

  Future<bool> processBulkPayments(Map<Unit, double> unitPayments, PaymentMethod method) async {
    bool allSuccessful = true;
    for (var entry in unitPayments.entries) {
      final unit = entry.key;
      final amount = entry.value;
      if (method == PaymentMethod.online) {
        final success = await processOnlinePayment(unit, amount);
        if (!success) allSuccessful = false;
      } else {
        processPayment(unit, amount, method);
      }
    }
    return allSuccessful;
  }
}

class ReportService {
  FundService fundService;
  ChargeService chargeService;
  PaymentService paymentService;

  ReportService(this.fundService, this.chargeService, this.paymentService);

  String generateFundReport() {
    return 'موجودی صندوق: ${fundService.getBalance()}\n'
        'تعداد هزینه‌ها: ${fundService.fund.costs.length}\n'
        'تعداد پرداخت‌ها: ${fundService.fund.payments.length}';
  }

  String generateUnitReport(Unit unit) {
    final charges = chargeService.getChargesForUnit(unit);
    final totalCharges = charges.fold(0.0, (sum, charge) => sum + charge.amount);
    return 'گزارش واحد ${unit.id}:\n'
        'موجودی: ${unit.balance}\n'
        'کل شارژها: $totalCharges';
  }

  String generateBillingStatement(Unit unit) {
    final charges = chargeService.getChargesForUnit(unit);
    final payments = paymentService.payments.where((p) => p.unit.id == unit.id).toList();
    final totalCharges = charges.fold(0.0, (sum, charge) => sum + charge.amount);
    final totalPayments = payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final unpaidCharges = chargeService.getUnpaidCharges(unit);

    String statement = 'صورتحساب واحد ${unit.id} (${unit.ownerName})\n';
    statement += '----------------------------------------\n';
    statement += 'موجودی فعلی: ${unit.balance}\n';
    statement += 'کل شارژهای ثبت‌شده: $totalCharges\n';
    statement += 'کل پرداخت‌ها: $totalPayments\n';
    statement += '\nجزئیات شارژها:\n';
    for (var charge in charges) {
      statement += '- ${charge.date.toString().substring(0, 10)}: ${charge.amount} (${charge.type}, ${charge.isPaid ? "پرداخت‌شده" : "پرداخت‌نشده"})\n';
    }
    statement += '\nجزئیات پرداخت‌ها:\n';
    for (var payment in payments) {
      statement += '- ${payment.date.toString().substring(0, 10)}: ${payment.amount} (${payment.method})\n';
    }
    statement += '\nشارژهای پرداخت‌نشده:\n';
    for (var charge in unpaidCharges) {
      statement += '- ${charge.date.toString().substring(0, 10)}: ${charge.amount} (${charge.type})\n';
    }
    return statement;
  }

  String generateOverdueReport(List<Unit> units) {
    final debtors = getDebtorUnits(units);
    String report = 'گزارش واحدهای بدهکار:\n';
    report += '----------------------------------------\n';
    if (debtors.isEmpty) {
      report += 'هیچ واحدی بدهکار نیست.\n';
    } else {
      for (var unit in debtors) {
        final unpaidCharges = chargeService.getUnpaidCharges(unit);
        final totalUnpaid = unpaidCharges.fold(0.0, (sum, charge) => sum + charge.amount);
        report += 'واحد ${unit.id} (${unit.ownerName}): بدهی ${totalUnpaid}\n';
      }
    }
    return report;
  }

  List<Unit> getDebtorUnits(List<Unit> units) {
    return units.where((unit) => unit.balance < 0).toList();
  }

  String exportBillingStatement(Unit unit, {String format = 'text'}) {
    final statement = generateBillingStatement(unit);
    if (format == 'pdf') {
      // TODO: Integrate with a PDF generation package (e.g., pdf)
      return 'PDF Export: $statement\n[Simulated PDF content for unit ${unit.id}]';
    } else if (format == 'email') {
      // TODO: Integrate with an email service
      return 'Email Export: $statement\n[Simulated email sent to ${unit.contactInfo ?? "no contact"}]';
    }
    return statement;
  }

  String generateAnalyticsDashboard(List<Unit> units) {
    final totalCharges = chargeService.charges.fold(0.0, (sum, charge) => sum + charge.amount);
    final totalPayments = paymentService.payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final debtorCount = getDebtorUnits(units).length;
    final totalUnpaid = chargeService.charges
        .where((charge) => !charge.isPaid)
        .fold(0.0, (sum, charge) => sum + charge.amount);

    String dashboard = 'داشبورد تحلیلی مجتمع:\n';
    dashboard += '----------------------------------------\n';
    dashboard += 'کل شارژهای ثبت‌شده: $totalCharges\n';
    dashboard += 'کل پرداخت‌ها: $totalPayments\n';
    dashboard += 'تعداد واحدهای بدهکار: $debtorCount\n';
    dashboard += 'کل بدهی‌های پرداخت‌نشده: $totalUnpaid\n';
    return dashboard;
  }
}

class ComplexManager {
  List<Building> buildings;
  final CostService costService;
  final PaymentService paymentService;
  final ChargeService chargeService;
  final ReportService reportService;
  List<AuditLog> auditLogs = [];

  ComplexManager({
    required this.buildings,
  })  : costService = CostService(),
        paymentService = PaymentService(),
        chargeService = ChargeService(),
        reportService = ReportService(
          FundService(Fund(id: 'complex_fund')),
          ChargeService(),
          PaymentService(),
        );

  void addBuilding(Building building) {
    buildings.add(building);
    logAction('add_building', 'system', 'ساختمان ${building.id} اضافه شد.');
  }

  List<Unit> getAllUnits() {
    return buildings.expand((building) => building.units).toList();
  }

  Map<String, List<Unit>> groupUnitsByOwner() {
    final Map<String, List<Unit>> groupedUnits = {};
    for (var unit in getAllUnits()) {
      groupedUnits.putIfAbsent(unit.ownerName, () => []).add(unit);
    }
    return groupedUnits;
  }

  void calculateComplexCharges(ChargeType type, double rate, {bool ownersOnly = false}) {
    for (var building in buildings) {
      final manager = BuildingManager(building, this);
      manager.calculateAndNotifyCharges(type, rate, ownersOnly: ownersOnly);
    }
    logAction('calculate_complex_charges', 'system', 'شارژهای مجتمع محاسبه شد.');
  }

  Future<bool> processComplexPayments(Map<Unit, double> unitPayments, PaymentMethod method) async {
    final success = await paymentService.processBulkPayments(unitPayments, method);
    logAction('process_complex_payments', 'system', 'پرداخت‌های گروهی برای ${unitPayments.length} واحد پردازش شد.');
    return success;
  }

  String getComplexOverdueReport() {
    String report = 'گزارش بدهی‌های مجتمع:\n';
    report += '----------------------------------------\n';
    for (var building in buildings) {
      report += 'ساختمان ${building.name}:\n';
      final manager = BuildingManager(building, this);
      report += manager.getOverdueReport();
      report += '\n';
    }
    return report;
  }

  String exportComplexBillingStatements({String format = 'text'}) {
    String result = 'صورتحساب‌های مجتمع:\n';
    result += '----------------------------------------\n';
    for (var building in buildings) {
      final manager = BuildingManager(building, this);
      for (var unit in building.units) {
        result += manager.exportBillingStatement(unit, format: format);
        result += '\n----------------------------------------\n';
      }
    }
    logAction('export_complex_billing_statements', 'system', 'صورتحساب‌های مجتمع صادر شد.');
    return result;
  }

  void logAction(String action, String userId, String details) {
    auditLogs.add(AuditLog(
      id: DateTime.now().toString(),
      action: action,
      userId: userId,
      timestamp: DateTime.now(),
      details: details,
    ));
  }

  String getAuditLogs() {
    String logs = 'گزارش لاگ‌های حسابرسی:\n';
    logs += '----------------------------------------\n';
    for (var log in auditLogs) {
      logs += '- ${log.timestamp.toString().substring(0, 16)}: ${log.action} توسط ${log.userId}: ${log.details}\n';
    }
    return logs;
  }
}

class BuildingManager {
  Building building;
  final CostService costService;
  final FundService fundService;
  final ChargeService chargeService;
  final PaymentService paymentService;
  final ReportService reportService;
  final List<User> users = [];
  final ComplexManager complexManager;

  BuildingManager(this.building, this.complexManager)
      : costService = complexManager.costService,
        fundService = FundService(building.fund),
        chargeService = complexManager.chargeService,
        paymentService = complexManager.paymentService,
        reportService = complexManager.reportService;

  void addCost(Cost cost, String userId) {
    if (_hasPermission(userId, UserRole.admin)) {
      costService.addCost(cost);
      fundService.addCost(cost);
      _logAction(userId, 'add_cost', 'هزینه ${cost.id} اضافه شد.');
    } else {
      debugPrint('خطا: کاربر $userId مجوز افزودن هزینه را ندارد.');
    }
  }

  void calculateAndNotifyCharges(ChargeType type, double rate, {bool ownersOnly = false}) {
    for (var unit in building.units) {
      chargeService.calculateCharge(unit, type, rate);
    }
    if (ownersOnly) {
      chargeService.notifyOwnersOnly(chargeService.charges);
    } else {
      chargeService.notifyResidents(chargeService.charges);
    }
  }

  Future<bool> processPayment(Unit unit, double amount, PaymentMethod method) async {
    if (method == PaymentMethod.online) {
      final success = await paymentService.processOnlinePayment(unit, amount);
      if (success) {
        fundService.addPayment(Payment(
          id: DateTime.now().toString(),
          unit: unit,
          amount: amount,
          method: method,
          date: DateTime.now(),
        ));
        final unpaidCharges = chargeService.getUnpaidCharges(unit);
        double remainingAmount = amount;
        for (var charge in unpaidCharges) {
          if (remainingAmount >= charge.amount) {
            charge.isPaid = true;
            remainingAmount -= charge.amount;
          } else {
            break;
          }
        }
        _logAction('system', 'process_payment', 'پرداخت $amount برای واحد ${unit.id} پردازش شد.');
      }
      return success;
    } else {
      paymentService.processPayment(unit, amount, method);
      fundService.addPayment(Payment(
        id: DateTime.now().toString(),
        unit: unit,
        amount: amount,
        method: method,
        date: DateTime.now(),
      ));
      final unpaidCharges = chargeService.getUnpaidCharges(unit);
      double remainingAmount = amount;
      for (var charge in unpaidCharges) {
        if (remainingAmount >= charge.amount) {
          charge.isPaid = true;
          remainingAmount -= charge.amount;
        } else {
          break;
        }
      }
      _logAction('system', 'process_payment', 'پرداخت $amount برای واحد ${unit.id} پردازش شد.');
      return true;
    }
  }

  Future<bool> sendPaymentLink(Unit unit, double amount) async {
    final paymentLink = await paymentService.generatePaymentLink(unit, amount);
    if (paymentLink != null && unit.contactInfo != null) {
      debugPrint('لینک پرداخت برای واحد ${unit.id} به ${unit.contactInfo} ارسال شد: $paymentLink');
      _logAction('system', 'send_payment_link', 'لینک پرداخت برای واحد ${unit.id} ارسال شد.');
      return true;
    } else {
      debugPrint('خطا در ارسال لینک پرداخت برای واحد ${unit.id}: اطلاعات تماس یا لینک نامعتبر است.');
      return false;
    }
  }

  String getFundReport() => reportService.generateFundReport();
  String getUnitReport(Unit unit) => reportService.generateUnitReport(unit);
  String getBillingStatement(Unit unit) => reportService.generateBillingStatement(unit);
  String getOverdueReport() => reportService.generateOverdueReport(building.units);
  List<Unit> getDebtorUnits() => reportService.getDebtorUnits(building.units);
  String exportBillingStatement(Unit unit, {String format = 'text'}) =>
      reportService.exportBillingStatement(unit, format: format);
  String getTransactionHistory() => fundService.getTransactionHistory();
  void scheduleRecurringCharges(ChargeType type, double rate, {int frequencyDays = 30}) {
    chargeService.calculateRecurringCharges(building.units, type, rate, frequencyDays: frequencyDays);
  }

  void addUser(User user) {
    if (users.any((u) => u.id == user.id)) {
      debugPrint('خطا: کاربر با شناسه ${user.id} قبلاً اضافه شده است.');
      return;
    }
    users.add(user);
    _logAction(user.id, 'add_user', 'کاربر ${user.name} با نقش ${user.role} اضافه شد.');
  }

  bool _hasPermission(String userId, UserRole requiredRole) {
    final user = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(id: '', name: '', role: UserRole.resident),
    );
    return user.role == requiredRole;
  }

  void _logAction(String userId, String action, String details) {
    complexManager.logAction(action, userId, details);
  }

  void sendPaymentReminders() {
    chargeService.sendPaymentReminders(building.units);
    _logAction('system', 'send_payment_reminders', 'یادآوری‌های پرداخت برای ساختمان ${building.id} ارسال شد.');
  }

  void proposeCost(Cost cost, String userId) {
    if (_hasPermission(userId, UserRole.admin) || _hasPermission(userId, UserRole.owner)) {
      costService.proposeCost(cost, userId);
      _logAction(userId, 'propose_cost', 'هزینه ${cost.id} توسط $userId پیشنهاد شد.');
    } else {
      debugPrint('خطا: کاربر $userId مجوز پیشنهاد هزینه را ندارد.');
    }
  }

  void approveCost(String costId, String approverId) {
    if (_hasPermission(approverId, UserRole.admin)) {
      if (costService.approveCost(costId, approverId)) {
        final cost = costService.getCosts().firstWhere((c) => c.id == costId);
        fundService.addCost(cost);
        _logAction(approverId, 'approve_cost', 'هزینه $costId توسط $approverId تأیید شد.');
      } else {
        debugPrint('خطا: هزینه $costId یافت نشد یا قبلاً تأیید شده است.');
      }
    } else {
      debugPrint('خطا: کاربر $approverId مجوز تأیید هزینه را ندارد.');
    }
  }

  String getAnalyticsDashboard() => reportService.generateAnalyticsDashboard(building.units);
}

// State Management with Provider
class ComplexManagerProvider extends ChangeNotifier {
  final ComplexManager complexManager;

  ComplexManagerProvider(this.complexManager);

  void notify() => notifyListeners();
}

// Flutter UI
void main() {
  runApp(const ApartmentaApp());
}

class ApartmentaApp extends StatelessWidget {
  const ApartmentaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final complexManager = ComplexManager(buildings: []);
        // Initialize sample data
        final building1 = Building(
          id: 'b1',
          name: 'ساختمان نمونه ۱',
          units: [
            Unit(
              id: 'u1',
              ownerName: 'علی',
              area: 100.0,
              residents: 4,
              parkingSlots: 1,
              contactInfo: 'ali@example.com',
            ),
            Unit(
              id: 'u2',
              ownerName: 'محمد',
              area: 120.0,
              residents: 3,
              parkingSlots: 2,
              contactInfo: 'mohammad@example.com',
            ),
          ],
          fund: Fund(id: 'f1'),
        );

        final building2 = Building(
          id: 'b2',
          name: 'ساختمان نمونه ۲',
          units: [
            Unit(
              id: 'u3',
              ownerName: 'علی',
              area: 80.0,
              residents: 2,
              parkingSlots: 1,
              contactInfo: 'ali@example.com',
            ),
          ],
          fund: Fund(id: 'f2'),
        );

        complexManager.addBuilding(building1);
        complexManager.addBuilding(building2);

        final buildingManager = BuildingManager(building1, complexManager);
        buildingManager.addUser(User(id: 'admin1', name: 'مدیر', role: UserRole.admin, contactInfo: 'admin@example.com'));
        buildingManager.addUser(User(id: 'owner1', name: 'علی', role: UserRole.owner, contactInfo: 'ali@example.com'));

        return ComplexManagerProvider(complexManager);
      },
      child: MaterialApp(
        title: 'Apartmenta',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16),
            headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl, // Support Persian RTL
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentUserId = 'admin1'; // Simulated logged-in user
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complexManager = Provider.of<ComplexManagerProvider>(context).complexManager;
    final List<Widget> screens = [
      DashboardScreen(complexManager: complexManager, currentUserId: currentUserId),
      BuildingsScreen(complexManager: complexManager, currentUserId: currentUserId),
      ChargesScreen(complexManager: complexManager, currentUserId: currentUserId),
      PaymentsScreen(complexManager: complexManager, currentUserId: currentUserId),
      ReportsScreen(complexManager: complexManager, currentUserId: currentUserId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت آپارتمان'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'داشبورد'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'ساختمان‌ها'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'شارژها'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'پرداخت‌ها'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'گزارش‌ها'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const DashboardScreen({super.key, required this.complexManager, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final buildingManager = BuildingManager(complexManager.buildings[0], complexManager);
    final dashboardData = buildingManager.getAnalyticsDashboard().split('\n').where((line) => line.contains(':')).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('داشبورد', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: dashboardData.map((data) {
                final parts = data.split(': ');
                return Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 40),
                        const SizedBox(height: 8),
                        Text(parts[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(parts[1], textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class BuildingsScreen extends StatelessWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const BuildingsScreen({super.key, required this.complexManager, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ساختمان‌ها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddBuildingDialog(complexManager: complexManager),
              );
            },
            child: const Text('افزودن ساختمان'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: complexManager.buildings.length,
              itemBuilder: (context, index) {
                final building = complexManager.buildings[index];
                return Card(
                  child: ListTile(
                    title: Text(building.name),
                    subtitle: Text('واحدها: ${building.units.length}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuildingDetailsScreen(
                            building: building,
                            complexManager: complexManager,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddBuildingDialog extends StatefulWidget {
  final ComplexManager complexManager;

  const AddBuildingDialog({super.key, required this.complexManager});

  @override
  State<AddBuildingDialog> createState() => _AddBuildingDialogState();
}

class _AddBuildingDialogState extends State<AddBuildingDialog> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String id = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن ساختمان جدید'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'شناسه ساختمان'),
              validator: (value) => value!.isEmpty ? 'شناسه نمی‌تواند خالی باشد' : null,
              onChanged: (value) => id = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'نام ساختمان'),
              validator: (value) => value!.isEmpty ? 'نام نمی‌تواند خالی باشد' : null,
              onChanged: (value) => name = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.complexManager.addBuilding(Building(
                id: id,
                name: name,
                units: [],
                fund: Fund(id: 'f_$id'),
              ));
              Provider.of<ComplexManagerProvider>(context, listen: false).notify();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ساختمان اضافه شد.')),
              );
            }
          },
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}

class BuildingDetailsScreen extends StatelessWidget {
  final Building building;
  final ComplexManager complexManager;
  final String currentUserId;

  const BuildingDetailsScreen({
    super.key,
    required this.building,
    required this.complexManager,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final buildingManager = BuildingManager(building, complexManager);
    return Scaffold(
      appBar: AppBar(
        title: Text(building.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddUnitDialog(building: building, buildingManager: buildingManager),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('واحدها', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: building.units.length,
                itemBuilder: (context, index) {
                  final unit = building.units[index];
                  return Card(
                    child: ListTile(
                      title: Text('واحد ${unit.id} (${unit.ownerName})'),
                      subtitle: Text('موجودی: ${unit.balance}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('صورتحساب واحد ${unit.id}'),
                            content: SingleChildScrollView(
                              child: Text(buildingManager.getBillingStatement(unit)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('بستن'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddUnitDialog extends StatefulWidget {
  final Building building;
  final BuildingManager buildingManager;

  const AddUnitDialog({super.key, required this.building, required this.buildingManager});

  @override
  State<AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<AddUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  String id = '';
  String ownerName = '';
  double area = 0.0;
  int residents = 0;
  int parkingSlots = 0;
  String? contactInfo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن واحد جدید'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'شناسه واحد'),
                validator: (value) => value!.isEmpty ? 'شناسه نمی‌تواند خالی باشد' : null,
                onChanged: (value) => id = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'نام مالک'),
                validator: (value) => value!.isEmpty ? 'نام نمی‌تواند خالی باشد' : null,
                onChanged: (value) => ownerName = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'متراژ'),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value!) == null ? 'متراژ نامعتبر' : null,
                onChanged: (value) => area = double.tryParse(value) ?? 0.0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'تعداد ساکنان'),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value!) == null ? 'تعداد نامعتبر' : null,
                onChanged: (value) => residents = int.tryParse(value) ?? 0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'تعداد پارکینگ'),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value!) == null ? 'تعداد نامعتبر' : null,
                onChanged: (value) => parkingSlots = int.tryParse(value) ?? 0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'اطلاعات تماس (اختیاری)'),
                onChanged: (value) => contactInfo = value.isEmpty ? null : value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.building.units.add(Unit(
                id: id,
                ownerName: ownerName,
                area: area,
                residents: residents,
                parkingSlots: parkingSlots,
                contactInfo: contactInfo,
              ));
              Provider.of<ComplexManagerProvider>(context, listen: false).notify();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('واحد اضافه شد.')),
              );
            }
          },
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}

class ChargesScreen extends StatefulWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const ChargesScreen({super.key, required this.complexManager, required this.currentUserId});

  @override
  State<ChargesScreen> createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  final _formKey = GlobalKey<FormState>();
  double rate = 10000;
  ChargeType chargeType = ChargeType.perArea;
  bool ownersOnly = true;

  @override
  Widget build(BuildContext context) {
    final buildingManager = BuildingManager(widget.complexManager.buildings[0], widget.complexManager);
    final isAdmin = buildingManager._hasPermission(widget.currentUserId, UserRole.admin);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مدیریت شارژها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<ChargeType>(
                  value: chargeType,
                  decoration: const InputDecoration(labelText: 'نوع شارژ'),
                  items: ChargeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == ChargeType.perArea
                          ? 'بر اساس متراژ'
                          : type == ChargeType.perResident
                              ? 'بر اساس تعداد ساکنان'
                              : 'بر اساس تعداد پارکینگ'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => chargeType = value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'نرخ (ریال)'),
                  keyboardType: TextInputType.number,
                  initialValue: '10000',
                  validator: (value) => double.tryParse(value!) == null ? 'نرخ نامعتبر' : null,
                  onChanged: (value) => rate = double.tryParse(value) ?? 10000,
                ),
                CheckboxListTile(
                  title: const Text('فقط به مالکان اطلاع‌رسانی شود'),
                  value: ownersOnly,
                  onChanged: (value) => setState(() => ownersOnly = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isAdmin
                ? () {
                    if (_formKey.currentState!.validate()) {
                      widget.complexManager.calculateComplexCharges(chargeType, rate, ownersOnly: ownersOnly);
                      Provider.of<ComplexManagerProvider>(context, listen: false).notify();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('شارژها محاسبه و اعلان‌ها ارسال شد.')),
                      );
                    }
                  }
                : null,
            child: const Text('محاسبه و ارسال شارژها'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isAdmin
                ? () {
                    buildingManager.sendPaymentReminders();
                    Provider.of<ComplexManagerProvider>(context, listen: false).notify();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('یادآوری‌های پرداخت ارسال شد.')),
                    );
                  }
                : null,
            child: const Text('ارسال یادآوری پرداخت'),
          ),
        ],
      ),
    );
  }
}

class PaymentsScreen extends StatefulWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const PaymentsScreen({super.key, required this.complexManager, required this.currentUserId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  Unit? selectedUnit;
  double amount = 500000;
  PaymentMethod paymentMethod = PaymentMethod.online;

  @override
  Widget build(BuildContext context) {
    final buildingManager = BuildingManager(widget.complexManager.buildings[0], widget.complexManager);
    final isAdmin = buildingManager._hasPermission(widget.currentUserId, UserRole.admin);
    final units = widget.complexManager.getAllUnits();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مدیریت پرداخت‌ها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<Unit>(
                  decoration: const InputDecoration(labelText: 'واحد'),
                  items: units.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text('واحد ${unit.id} (${unit.ownerName})'),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'واحد را انتخاب کنید' : null,
                  onChanged: (value) => setState(() => selectedUnit = value),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'مبلغ (ریال)'),
                  keyboardType: TextInputType.number,
                  initialValue: '500000',
                  validator: (value) => double.tryParse(value!) == null ? 'مبلغ نامعتبر' : null,
                  onChanged: (value) => amount = double.tryParse(value) ?? 500000,
                ),
                DropdownButtonFormField<PaymentMethod>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'روش پرداخت'),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method == PaymentMethod.online
                          ? 'آنلاین'
                          : method == PaymentMethod.cash
                              ? 'نقدی'
                              : method == PaymentMethod.cardToCard
                                  ? 'کارت به کارت'
                                  : 'پیش‌پرداخت'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => paymentMethod = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isAdmin && selectedUnit != null
                ? () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await buildingManager.processPayment(selectedUnit!, amount, paymentMethod);
                      if (success) {
                        Provider.of<ComplexManagerProvider>(context, listen: false).notify();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('پرداخت با موفقیت ثبت شد.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('خطا در پردازش پرداخت')),
                        );
                      }
                    }
                  }
                : null,
            child: const Text('پردازش پرداخت'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isAdmin && selectedUnit != null
                ? () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await buildingManager.sendPaymentLink(selectedUnit!, amount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'لینک پرداخت ارسال شد.' : 'خطا در ارسال لینک پرداخت')),
                      );
                    }
                  }
                : null,
            child: const Text('ارسال لینک پرداخت'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isAdmin && widget.complexManager.buildings.length > 1
                ? () async {
                    final payments = {
                      widget.complexManager.buildings[0].units[0]: 500000.0,
                      widget.complexManager.buildings[1].units[0]: 300000.0,
                    };
                    final success = await widget.complexManager.processComplexPayments(payments, PaymentMethod.online);
                    Provider.of<ComplexManagerProvider>(context, listen: false).notify();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'پرداخت‌ها با موفقیت انجام شد.' : 'خطا در پردازش پرداخت‌ها')),
                    );
                  }
                : null,
            child: const Text('پردازش پرداخت‌های گروهی'),
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const ReportsScreen({super.key, required this.complexManager, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final buildingManager = BuildingManager(complexManager.buildings[0], complexManager);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('گزارش‌ها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance, color: Colors.blue),
                    title: const Text('گزارش صندوق'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('گزارش صندوق'),
                          content: SingleChildScrollView(
                            child: Text(buildingManager.getFundReport()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('بستن'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: const Text('گزارش بدهی‌ها'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('گزارش بدهی‌ها'),
                          content: SingleChildScrollView(
                            child: Text(complexManager.getComplexOverdueReport()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('بستن'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: const Text('لاگ‌های حسابرسی'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('لاگ‌های حسابرسی'),
                          content: SingleChildScrollView(
                            child: Text(complexManager.getAuditLogs()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('بستن'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}