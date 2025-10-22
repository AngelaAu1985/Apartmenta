import 'package:apartmenta/apartmenta.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApartmentApp(prefs: prefs));
}

class MyApartmentApp extends StatelessWidget {
  final SharedPreferences prefs;

  MyApartmentApp({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        // Initialize ComplexManager with a sample building
        final complexManager = ComplexManager(buildings: []);
        // Load or initialize buildings
        final building1 = Building(
          id: 'b1',
          name: 'برج آفتاب',
          units: [
            Unit(id: 'u1', ownerName: 'علی احمدی', area: 100.0, residents: 4, parkingSlots: 1, contactInfo: 'ali@example.com'),
            Unit(id: 'u2', ownerName: 'محمد رضایی', area: 120.0, residents: 3, parkingSlots: 2, contactInfo: 'mohammad@example.com'),
          ],
          fund: Fund(id: 'f1'),
        );
        complexManager.addBuilding(building1);

        // Add admin and owner users
        final buildingManager = BuildingManager(building1, complexManager);
        buildingManager.addUser(User(id: 'admin1', name: 'مدیر', role: UserRole.admin, contactInfo: 'admin@example.com'));
        buildingManager.addUser(User(id: 'owner1', name: 'علی احمدی', role: UserRole.owner, contactInfo: 'ali@example.com'));

        return ComplexManagerProvider(complexManager);
      },
      child: MaterialApp(
        title: 'Apartment Management',
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
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: MyHomeScreen(prefs: prefs),
      ),
    );
  }
}

class MyHomeScreen extends StatefulWidget {
  final SharedPreferences prefs;

  MyHomeScreen({required this.prefs});

  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  String currentUserId = 'admin1'; // Default logged-in user
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load current user from preferences
    currentUserId = widget.prefs.getString('currentUserId') ?? 'admin1';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complexManager = Provider.of<ComplexManagerProvider>(context).complexManager;
    final buildingManager = BuildingManager(complexManager.buildings[0], complexManager);
    final isAdmin = buildingManager._hasPermission(currentUserId, UserRole.admin);

    final List<Widget> screens = [
      DashboardScreen(complexManager: complexManager, currentUserId: currentUserId),
      UnitsScreen(complexManager: complexManager, currentUserId: currentUserId),
      ChargesScreen(complexManager: complexManager, currentUserId: currentUserId),
      PaymentsScreen(complexManager: complexManager, currentUserId: currentUserId),
      ReportsScreen(complexManager: complexManager, currentUserId: currentUserId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت مجتمع'),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'مدیریت آپارتمان',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('داشبورد'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.apartment),
              title: Text('واحدها'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.monetization_on),
              title: Text('شارژها'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('پرداخت‌ها'),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('گزارش‌ها'),
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('تنظیمات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(prefs: widget.prefs, currentUserId: currentUserId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'داشبورد'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'واحدها'),
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

  const DashboardScreen({Key? key, required this.complexManager, required this.currentUserId}) : super(key: key);

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

class UnitsScreen extends StatelessWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const UnitsScreen({Key? key, required this.complexManager, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final units = complexManager.getAllUnits();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('واحدها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final buildingManager = BuildingManager(complexManager.buildings[0], complexManager);
                return Card(
                  child: ListTile(
                    title: Text('واحد ${unit.id} (${unit.ownerName})'),
                    subtitle: Text('موجودی: ${unit.balance} | متراژ: ${unit.area}'),
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
    );
  }
}

class ChargesScreen extends StatefulWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const ChargesScreen({Key? key, required this.complexManager, required this.currentUserId}) : super(key: key);

  @override
  _ChargesScreenState createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  final _formKey = GlobalKey<FormState>();
  double rate = 10000;
  ChargeType chargeType = ChargeType.perArea;
  bool ownersOnly = true;
  bool isLoading = false;

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
          isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: isAdmin
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              widget.complexManager.calculateComplexCharges(chargeType, rate, ownersOnly: ownersOnly);
                              Provider.of<ComplexManagerProvider>(context, listen: false).notify();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('شارژها محاسبه و اعلان‌ها ارسال شد.')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('خطا: $e')),
                              );
                            } finally {
                              setState(() => isLoading = false);
                            }
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

  const PaymentsScreen({Key? key, required this.complexManager, required this.currentUserId}) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  Unit? selectedUnit;
  double amount = 500000;
  PaymentMethod paymentMethod = PaymentMethod.online;
  bool isLoading = false;

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
          isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: isAdmin && selectedUnit != null
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              final success = await buildingManager.processPayment(selectedUnit!, amount, paymentMethod);
                              Provider.of<ComplexManagerProvider>(context, listen: false).notify();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(success ? 'پرداخت موفق' : 'خطا در پرداخت')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('خطا: $e')),
                              );
                            } finally {
                              setState(() => isLoading = false);
                            }
                          }
                        }
                      : null,
                  child: const Text('پردازش پرداخت'),
                ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final ComplexManager complexManager;
  final String currentUserId;

  const ReportsScreen({Key? key, required this.complexManager, required this.currentUserId}) : super(key: key);

  @override
  Widget build(Context context) {
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

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final String currentUserId;

  const SettingsScreen({Key? key, required this.prefs, required this.currentUserId}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedUserId = '';

  @override
  void initState() {
    super.initState();
    selectedUserId = widget.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final complexManager = Provider.of<ComplexManagerProvider>(context).complexManager;
    final buildingManager = BuildingManager(complexManager.buildings[0], complexManager);
    final users = buildingManager.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تغییر کاربر', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedUserId,
              decoration: const InputDecoration(labelText: 'کاربر'),
              items: users.map((user) {
                return DropdownMenuItem(
                  value: user.id,
                  child: Text('${user.name} (${user.role == UserRole.admin ? 'مدیر' : user.role == UserRole.owner ? 'مالک' : 'ساکن'})'),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() => selectedUserId = value!);
                await widget.prefs.setString('currentUserId', selectedUserId);
                Provider.of<ComplexManagerProvider>(context, listen: false).notify();
              },
            ),
          ],
        ),
      ),
    );
  }
}