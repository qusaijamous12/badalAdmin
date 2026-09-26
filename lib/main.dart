import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _pine = Color(0xFF154C3B);
const _mint = Color(0xFFE9F3E9);
const _ink = Color(0xFF142D25);
const _muted = Color(0xFF6D8077);
const _canvas = Color(0xFFF5F7F2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDI0GtA4Lk_OsxBk48CSvwUxortzNPWhAc',
      authDomain: 'badal-c59cb.firebaseapp.com',
      projectId: 'badal-c59cb',
      storageBucket: 'badal-c59cb.firebasestorage.app',
      messagingSenderId: '424302103101',
      appId: '1:424302103101:web:19b395605163de1d24f854',
      measurementId: 'G-8F8E44MT3W',
    ),
  );
  runApp(const BadalAdminApp());
}

class BadalAdminApp extends StatelessWidget {
  const BadalAdminApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'بدل | لوحة الإدارة',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: _pine),
      fontFamily: 'Arial',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE5DD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE5DD))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      ),
    ),
    home: const Directionality(textDirection: TextDirection.rtl, child: AuthGate()),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) return const _BusyScreen();
      final user = auth.data;
      if (user == null) return const LoginPage();
      return FutureBuilder<IdTokenResult>(
        key: ValueKey(user.uid),
        future: user.getIdTokenResult(true),
        builder: (context, token) {
          if (token.connectionState != ConnectionState.done) return const _BusyScreen();
          if (token.hasError) return _AccessPage(message: 'تعذر التحقق من الصلاحيات. تحقق من الاتصال وأعد المحاولة.');
          if (token.data?.claims?['admin'] != true) {
            return const _AccessPage(message: 'هذا الحساب لا يملك صلاحية إدارة بدل.');
          }
          return const DashboardPage();
        },
      );
    },
  );
}

class _BusyScreen extends StatelessWidget {
  const _BusyScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AccessPage extends StatelessWidget {
  const _AccessPage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: _Panel(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.admin_panel_settings_outlined, size: 52, color: _pine),
      const SizedBox(height: 18),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      FilledButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('العودة لتسجيل الدخول')),
    ])),
  )));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'admin@gmail.com');
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = switch (e.code) {
          'invalid-credential' || 'wrong-password' || 'user-not-found' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
          'too-many-requests' => 'محاولات كثيرة. حاول مرة أخرى لاحقًا.',
          'operation-not-allowed' => 'تسجيل الدخول بالبريد غير مفعّل في Firebase.',
          _ => 'تعذر تسجيل الدخول: ${e.message ?? e.code}',
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'حدث خطأ في الاتصال. حاول مجددًا.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: LayoutBuilder(builder: (context, box) {
    final wide = box.maxWidth > 850;
    return Row(children: [
      if (wide) Expanded(child: Container(
        decoration: const BoxDecoration(color: _pine),
        padding: const EdgeInsets.all(70),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.autorenew_rounded, color: Color(0xFFCAEED7), size: 68),
          const SizedBox(height: 30),
          const Text('بدل', style: TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('مساحة أذكى لتبادل الأشياء\nوبناء مجتمع أكثر استدامة.', style: TextStyle(color: Color(0xFFE2F3E8), fontSize: 25, height: 1.6, fontWeight: FontWeight.w600)),
          const SizedBox(height: 42),
          Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)), child: const Text('لوحة التحكم الإدارية', style: TextStyle(color: Colors.white))),
        ]),
      )),
      Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!wide) const Row(children: [Icon(Icons.autorenew_rounded, color: _pine, size: 38), SizedBox(width: 10), Text('بدل', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _pine))]),
          const SizedBox(height: 30),
          const Text('مرحبًا بعودتك', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 8),
          const Text('سجّل الدخول لإدارة مجتمع بدل ومتابعة نشاط المقايضات.', style: TextStyle(color: _muted, height: 1.6)),
          const SizedBox(height: 36),
          const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (v) => v == null || !v.contains('@') ? 'أدخل بريدًا إلكترونيًا صحيحًا' : null),
          const SizedBox(height: 20),
          const Text('كلمة المرور', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(controller: _password, obscureText: _hidden, textDirection: TextDirection.ltr, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _hidden = !_hidden), icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == null || v.isEmpty ? 'أدخل كلمة المرور' : null, onFieldSubmitted: (_) => _login()),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: Color(0xFFB33939)))),
          const SizedBox(height: 26),
          SizedBox(height: 54, child: FilledButton(onPressed: _busy ? null : _login, style: FilledButton.styleFrom(backgroundColor: _pine), child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
          const SizedBox(height: 16),
          const Text('هذه المساحة مخصصة للمشرفين المصرّح لهم فقط.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
        ])),
      )))),
    ]);
  }));
}

class DashboardController extends GetxController {
  final section = 0.obs;
  final search = ''.obs;
  final status = 'الكل'.obs;
  final busyItem = ''.obs;
  final db = FirebaseFirestore.instance;

  Future<void> setItemHidden(QueryDocumentSnapshot<Map<String, dynamic>> item, bool hidden) async {
    busyItem.value = item.id;
    try {
      await item.reference.update({'status': hidden ? 'hidden' : 'available'});
      Get.snackbar('تم التحديث', hidden ? 'تم إخفاء الغرض من التطبيق.' : 'أصبح الغرض متاحًا للمقايضة.', snackPosition: SnackPosition.BOTTOM, backgroundColor: _mint);
    } on FirebaseException catch (e) {
      Get.snackbar('تعذر التحديث', e.message ?? e.code, snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFFFFE9E5));
    } finally {
      busyItem.value = '';
    }
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController c = Get.put(DashboardController());

  @override
  void dispose() {
    Get.delete<DashboardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: c.db.collection('items').snapshots(),
    builder: (context, itemsSnap) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: c.db.collection('offers').snapshots(),
      builder: (context, offersSnap) {
        final items = itemsSnap.data?.docs ?? [];
        final offers = offersSnap.data?.docs ?? [];
        final error = itemsSnap.error ?? offersSnap.error;
        return LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 920;
          return Scaffold(
            appBar: wide ? null : AppBar(title: const Text('بدل | الإدارة'), backgroundColor: Colors.white),
            drawer: wide ? null : Drawer(child: _Sidebar(c: c, onSelected: () => Navigator.pop(context))),
            body: Row(children: [
              if (wide) SizedBox(width: 246, child: _Sidebar(c: c)),
              Expanded(child: Obx(() {
                final section = c.section.value;
                final query = c.search.value.trim().toLowerCase();
                final status = c.status.value;
                return SingleChildScrollView(padding: EdgeInsets.all(wide ? 34 : 18), child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Header(section: section, wide: wide),
                    const SizedBox(height: 28),
                    if (error != null) _Notice('تعذر تحميل البيانات. تأكد من قواعد Firestore وصلاحية حساب المشرف.\n$error')
                    else if (!itemsSnap.hasData || !offersSnap.hasData) const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
                    else if (section == 0) _Overview(items: items, offers: offers, openSection: (i) => c.section.value = i)
                    else if (section == 1) _ItemsView(items: items, query: query, status: status, c: c)
                    else if (section == 2) _OffersView(offers: offers, query: query, db: c.db)
                    else _PeopleView(items: items, offers: offers, query: query),
                  ]),
                ));
              })),
            ]),
          );
        });
      },
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.c, this.onSelected});
  final DashboardController c;
  final VoidCallback? onSelected;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 34, 16, 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [CircleAvatar(backgroundColor: _pine, child: Icon(Icons.autorenew_rounded, color: Colors.white)), SizedBox(width: 10), Text('بدل', style: TextStyle(color: _pine, fontSize: 27, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 8),
      const Text('لوحة الإدارة', style: TextStyle(color: _muted)),
      const SizedBox(height: 38),
      for (final (i, label, icon) in [(0, 'نظرة عامة', Icons.dashboard_outlined), (1, 'الأغراض', Icons.inventory_2_outlined), (2, 'المقايضات', Icons.swap_horiz_rounded), (3, 'المستخدمون', Icons.people_outline_rounded)])
        Obx(() => Padding(padding: const EdgeInsets.only(bottom: 8), child: ListTile(
          selected: c.section.value == i,
          selectedTileColor: _mint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: c.section.value == i ? _pine : _muted),
          title: Text(label, style: TextStyle(fontWeight: c.section.value == i ? FontWeight.w800 : FontWeight.w500, color: c.section.value == i ? _pine : _ink)),
          onTap: () { c.section.value = i; c.search.value = ''; c.status.value = 'الكل'; onSelected?.call(); },
        ))),
      const Spacer(),
      const Divider(),
      ListTile(leading: const Icon(Icons.logout_rounded, color: _muted), title: const Text('تسجيل الخروج'), onTap: () => FirebaseAuth.instance.signOut()),
    ]),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.section, required this.wide});
  final int section;
  final bool wide;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(['نظرة عامة', 'إدارة الأغراض', 'المقايضات', 'المستخدمون'][section], style: TextStyle(color: _ink, fontSize: wide ? 30 : 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(['تابع نشاط المجتمع لحظة بلحظة', 'راجع الأغراض المنشورة وتحكم في ظهورها', 'راقب طلبات التبادل ومحادثاتها', 'أصحاب الأغراض والمشاركون في المقايضات'][section], style: const TextStyle(color: _muted)),
    ])),
    if (wide) Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)), child: Row(children: [const CircleAvatar(radius: 16, backgroundColor: _mint, child: Icon(Icons.person_outline, size: 18, color: _pine)), const SizedBox(width: 8), Text(FirebaseAuth.instance.currentUser?.email ?? 'المشرف', style: const TextStyle(fontSize: 12))])),
  ]);
}

class _Overview extends StatelessWidget {
  const _Overview({required this.items, required this.offers, required this.openSection});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> offers;
  final ValueChanged<int> openSection;
  @override
  Widget build(BuildContext context) {
    final people = <String>{};
    for (final item in items) { final id = item.data()['ownerId']; if (id is String) people.add(id); }
    for (final offer in offers) { for (final key in ['ownerId', 'requesterId']) { final id = offer.data()[key]; if (id is String) people.add(id); } }
    final recent = [...offers]..sort((a, b) => _date(b.data()['createdAt']).compareTo(_date(a.data()['createdAt'])));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: _pine, borderRadius: BorderRadius.circular(22)), child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 18, runSpacing: 18, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('أهلًا بك في بدل 👋', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('كل غرض يجد بيتًا جديدًا يترك أثرًا أخف على كوكبنا.', style: TextStyle(color: Color(0xFFE1F0E4)))],),
        const Icon(Icons.eco_outlined, color: Color(0xFFBDE8C8), size: 65),
      ])),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, box) => Wrap(spacing: 14, runSpacing: 14, children: [
        _Stat('الأغراض المنشورة', '${items.length}', Icons.inventory_2_outlined, box.maxWidth),
        _Stat('المتاحة الآن', '${items.where((e) => e.data()['status'] == 'available').length}', Icons.check_circle_outline, box.maxWidth),
        _Stat('طلبات المقايضة', '${offers.length}', Icons.swap_horiz_rounded, box.maxWidth),
        _Stat('المشاركون', '${people.length}', Icons.people_outline_rounded, box.maxWidth),
      ])),
      const SizedBox(height: 27),
      Row(children: [const Expanded(child: Text('آخر المقايضات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink))), TextButton(onPressed: () => openSection(2), child: const Text('عرض الكل ←'))]),
      const SizedBox(height: 12),
      _Panel(child: recent.isEmpty ? const _Empty('لا توجد مقايضات بعد') : Column(children: [for (final offer in recent.take(5)) _OfferLine(offer: offer, onTap: null)])),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.totalWidth);
  final String label, value;
  final IconData icon;
  final double totalWidth;
  @override
  Widget build(BuildContext context) {
    final width = totalWidth >= 1100 ? (totalWidth - 42) / 4 : totalWidth >= 560 ? (totalWidth - 14) / 2 : totalWidth;
    return SizedBox(width: width, child: _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: _pine)),
      const SizedBox(height: 18),
      Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)),
      Text(label, style: const TextStyle(color: _muted)),
    ])));
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView({required this.items, required this.query, required this.status, required this.c});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
  final String query, status;
  final DashboardController c;
  @override
  Widget build(BuildContext context) {
    final filtered = items.where((d) {
      final x = d.data();
      return (status == 'الكل' || x['status'] == status) && '${x['title']} ${x['ownerName']} ${x['category']}'.toLowerCase().contains(query);
    }).toList()..sort((a, b) => _date(b.data()['createdAt']).compareTo(_date(a.data()['createdAt'])));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Filters(c: c, hint: 'ابحث باسم الغرض أو صاحبه أو التصنيف', statuses: const {'الكل': 'الكل', 'available': 'متاح', 'reserved': 'محجوز', 'exchanged': 'تم التبادل', 'hidden': 'مخفي'}),
      const SizedBox(height: 14),
      Text('${filtered.length} غرض', style: const TextStyle(color: _muted)),
      const SizedBox(height: 14),
      if (filtered.isEmpty) const _Panel(child: _Empty('لا توجد أغراض مطابقة')),
      LayoutBuilder(builder: (context, box) => Wrap(spacing: 14, runSpacing: 14, children: [
        for (final item in filtered) SizedBox(width: box.maxWidth >= 1050 ? (box.maxWidth - 28) / 3 : box.maxWidth >= 650 ? (box.maxWidth - 14) / 2 : box.maxWidth, child: _ItemCard(item: item, c: c)),
      ])),
    ]);
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.c});
  final QueryDocumentSnapshot<Map<String, dynamic>> item;
  final DashboardController c;
  @override
  Widget build(BuildContext context) {
    final data = item.data();
    final state = data['status'] as String? ?? '';
    final bytes = data['image'] is Blob ? (data['image'] as Blob).bytes : null;
    return _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 150, width: double.infinity, child: bytes == null ? Container(color: _mint, child: const Icon(Icons.image_outlined, color: _pine, size: 46)) : Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined)))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: Text('${data['title'] ?? 'غرض'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), _Badge(_itemStatus(state))]),
      const SizedBox(height: 8),
      Text('${data['category'] ?? '—'} · ${data['condition'] ?? '—'}', style: const TextStyle(color: _muted)),
      const SizedBox(height: 7),
      Text('بواسطة ${data['ownerName'] ?? data['ownerId'] ?? 'مستخدم'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 14),
      if (state == 'available' || state == 'hidden') Obx(() => SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: c.busyItem.value == item.id ? null : () => _confirmItemAction(context, item, c, state == 'available'),
        icon: Icon(state == 'available' ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
        label: Text(c.busyItem.value == item.id ? 'جارٍ التحديث...' : state == 'available' ? 'إخفاء الغرض' : 'إعادة إظهار الغرض'),
      ))),
    ]));
  }
}

Future<void> _confirmItemAction(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> item, DashboardController c, bool hidden) async {
  final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
    title: Text(hidden ? 'إخفاء الغرض؟' : 'إعادة إظهار الغرض؟'),
    content: Text(hidden ? 'لن يظهر هذا الغرض في الاكتشاف أو يقبل عروضًا جديدة حتى تعيد إظهاره.' : 'سيظهر هذا الغرض مرة أخرى في قائمة الأغراض المتاحة.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد'))],
  ));
  if (approved == true) await c.setItemHidden(item, hidden);
}

class _OffersView extends StatelessWidget {
  const _OffersView({required this.offers, required this.query, required this.db});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> offers;
  final String query;
  final FirebaseFirestore db;
  @override
  Widget build(BuildContext context) {
    final c = Get.find<DashboardController>();
    final filtered = offers.where((d) { final x = d.data(); return '${x['targetTitle']} ${x['offeredTitle']} ${x['ownerName']} ${x['requesterName']}'.toLowerCase().contains(query) && (c.status.value == 'الكل' || x['status'] == c.status.value); }).toList()..sort((a, b) => _date(b.data()['createdAt']).compareTo(_date(a.data()['createdAt'])));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Filters(c: c, hint: 'ابحث في الأغراض أو أسماء المشاركين', statuses: const {'الكل': 'الكل', 'pending': 'قيد الانتظار', 'accepted': 'مقبول', 'declined': 'مرفوض', 'cancelled': 'ملغى', 'completed': 'مكتمل'}),
      const SizedBox(height: 16),
      Text('${filtered.length} طلب مقايضة', style: const TextStyle(color: _muted)),
      const SizedBox(height: 14),
      _Panel(child: filtered.isEmpty ? const _Empty('لا توجد مقايضات مطابقة') : Column(children: [for (final offer in filtered) _OfferLine(offer: offer, onTap: () => _showOffer(context, offer, db))])),
    ]);
  }
}

class _OfferLine extends StatelessWidget {
  const _OfferLine({required this.offer, required this.onTap});
  final QueryDocumentSnapshot<Map<String, dynamic>> offer;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final d = offer.data();
    return Column(children: [ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7),
      leading: const CircleAvatar(backgroundColor: _mint, child: Icon(Icons.swap_horiz, color: _pine)),
      title: Text('${d['offeredTitle'] ?? 'غرض'} ↔ ${d['targetTitle'] ?? 'غرض'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${d['requesterName'] ?? 'مستخدم'} · ${d['ownerName'] ?? 'مستخدم'}    ${_formatDate(d['createdAt'])}', maxLines: 2),
      trailing: _Badge(_offerStatus(d['status'] as String? ?? '')),
      onTap: onTap,
    ), const Divider(height: 1)]);
  }
}

void _showOffer(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> offer, FirebaseFirestore db) {
  final d = offer.data();
  showDialog<void>(context: context, builder: (context) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620, maxHeight: 650), child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [const Expanded(child: Text('تفاصيل المقايضة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
    const SizedBox(height: 14),
    Text('${d['offeredTitle'] ?? 'غرض'} ↔ ${d['targetTitle'] ?? 'غرض'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Text('مقدم العرض: ${d['requesterName'] ?? '—'}   ·   صاحب الغرض: ${d['ownerName'] ?? '—'}', style: const TextStyle(color: _muted)),
    const SizedBox(height: 6),
    Text('الحالة: ${_offerStatus(d['status'] as String? ?? '')}   ·   ${_formatDate(d['createdAt'])}', style: const TextStyle(color: _muted)),
    const Divider(height: 30),
    const Text('المحادثة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
    const SizedBox(height: 10),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: db.collection('offers').doc(offer.id).collection('messages').orderBy('createdAt').snapshots(), builder: (context, snap) {
      if (snap.hasError) return const _Empty('تعذر تحميل المحادثة');
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      if (snap.data!.docs.isEmpty) return const _Empty('لا توجد رسائل بعد');
      return ListView.separated(itemCount: snap.data!.docs.length, separatorBuilder: (_, _) => const SizedBox(height: 8), itemBuilder: (context, index) {
        final m = snap.data!.docs[index].data();
        final sender = m['senderId'] == d['ownerId'] ? (d['ownerName'] ?? 'صاحب الغرض') : (d['requesterName'] ?? 'مقدم العرض');
        return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _canvas, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$sender', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _pine)), const SizedBox(height: 4), Text('${m['body'] ?? ''}'), const SizedBox(height: 4), Text(_formatDate(m['createdAt']), style: const TextStyle(fontSize: 11, color: _muted))]));
      });
    })),
  ])))));
}

class _PeopleView extends StatelessWidget {
  const _PeopleView({required this.items, required this.offers, required this.query});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> offers;
  final String query;
  @override
  Widget build(BuildContext context) {
    final people = <String, _Person>{};
    for (final item in items) {
      final d = item.data(); final id = d['ownerId'] as String?;
      if (id != null) { final p = people.putIfAbsent(id, () => _Person(id, '${d['ownerName'] ?? 'مستخدم'}')); p.items++; }
    }
    for (final offer in offers) {
      final d = offer.data();
      for (final (idKey, nameKey) in [('ownerId', 'ownerName'), ('requesterId', 'requesterName')]) {
        final id = d[idKey] as String?;
        if (id != null) { final p = people.putIfAbsent(id, () => _Person(id, '${d[nameKey] ?? 'مستخدم'}')); p.offers++; }
      }
    }
    final filtered = people.values.where((p) => '${p.name} ${p.id}'.toLowerCase().contains(query)).toList()..sort((a, b) => a.name.compareTo(b.name));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Notice('تُعرض هنا الحسابات التي نشرت غرضًا أو شاركت في مقايضة. لا يتيح Firebase Auth استعراض كل الحسابات مباشرة من تطبيق العميل.'),
      const SizedBox(height: 18),
      _Filters(c: Get.find<DashboardController>(), hint: 'ابحث باسم المستخدم أو المعرّف'),
      const SizedBox(height: 16),
      Text('${filtered.length} مشارك', style: const TextStyle(color: _muted)),
      const SizedBox(height: 14),
      _Panel(child: filtered.isEmpty ? const _Empty('لا يوجد مستخدمون مطابقون') : Column(children: [for (final p in filtered) Column(children: [ListTile(leading: const CircleAvatar(backgroundColor: _mint, child: Icon(Icons.person_outline, color: _pine)), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('أغراض: ${p.items}    ·    مقايضات: ${p.offers}\n${p.id}', style: const TextStyle(color: _muted, fontSize: 12)), isThreeLine: true), const Divider(height: 1)])])),
    ]);
  }
}

class _Person {
  _Person(this.id, this.name);
  final String id, name;
  int items = 0, offers = 0;
}

class _Filters extends StatelessWidget {
  const _Filters({required this.c, required this.hint, this.statuses});
  final DashboardController c;
  final String hint;
  final Map<String, String>? statuses;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 12, children: [
    SizedBox(width: 330, child: TextField(key: ValueKey(c.section.value), onChanged: (v) => c.search.value = v, decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search), isDense: true))),
    if (statuses != null) Obx(() => Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFDDE5DD)), borderRadius: BorderRadius.circular(14)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: c.status.value, items: [for (final e in statuses!.entries) DropdownMenuItem(value: e.key, child: Text(e.value))], onChanged: (v) { if (v != null) c.status.value = v; })))),
  ]);
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8EEE8))), child: child);
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(color: _pine, fontSize: 11, fontWeight: FontWeight.w700)));
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _muted))));
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(12)), child: Text(text, style: const TextStyle(color: _pine, height: 1.5)));
}

DateTime _date(dynamic value) => value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
String _formatDate(dynamic value) { final d = _date(value); return d.year == 1970 ? '' : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'; }
String _itemStatus(String status) => switch (status) { 'available' => 'متاح', 'reserved' => 'محجوز', 'exchanged' => 'تم التبادل', 'hidden' => 'مخفي', _ => status };
String _offerStatus(String status) => switch (status) { 'pending' => 'قيد الانتظار', 'accepted' => 'مقبول', 'declined' => 'مرفوض', 'cancelled' => 'ملغى', 'completed' => 'مكتمل', _ => status };
