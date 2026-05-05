import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/staff_model.dart';
import 'unified_pos_screen.dart';

class KioskLoginScreen extends StatelessWidget {
  const KioskLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final staff = auth.activeStaff;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 56),
            // Logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE8445A),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8445A).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('Z',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Zen POS',
                style: TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Vyberte svůj profil',
                style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 48),

            // Staff tiles
            Expanded(
              child: staff.isEmpty
                  ? const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14, color: Color(0xFFE8445A)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 160,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: staff.length,
                        itemBuilder: (context, i) => _StaffTile(
                          member: staff[i],
                          roleName:
                              auth.getRoleById(staff[i].roleId)?.name ?? '',
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            const Text('© Zen POS 2025',
                style: TextStyle(
                    color: Color(0xFFC7C7CC),
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final StaffMember member;
  final String roleName;
  const _StaffTile({required this.member, required this.roleName});

  @override
  Widget build(BuildContext context) {
    final initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => showDialog(
          context: context,
          builder: (ctx) => _PinDialog(member: member)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8445A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        color: Color(0xFFE8445A),
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            Text(member.name,
                style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(roleName,
                style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  final StaffMember member;
  const _PinDialog({required this.member});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';
  bool _error = false;

  void _addDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length == 4) _tryLogin();
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  void _tryLogin() {
    final auth = context.read<AuthViewModel>();
    if (auth.loginWithPin(widget.member.id, _pin)) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UnifiedPOSScreen()));
    } else {
      setState(() {
        _pin = '';
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 24,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8445A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    widget.member.name.isNotEmpty
                        ? widget.member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Color(0xFFE8445A),
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.member.name,
                  style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _error ? 'Špatný PIN, zkuste znovu' : 'Zadejte PIN',
                style: TextStyle(
                    color: _error
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF8E8E93),
                    fontSize: 14),
              ),
              const SizedBox(height: 20),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_error
                              ? const Color(0xFFFF3B30)
                              : const Color(0xFFE8445A))
                          : const Color(0xFFE5E5EA),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Keypad
              ...[
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['', '0', 'del'],
              ].map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((k) {
                        if (k.isEmpty) {
                          return const SizedBox(width: 72, height: 52);
                        }
                        if (k == 'del') {
                          return _key(
                            child: const Icon(Icons.backspace_outlined,
                                size: 20, color: Color(0xFF3C3C43)),
                            onTap: _delete,
                          );
                        }
                        return _key(
                          child: Text(k,
                              style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400)),
                          onTap: () => _addDigit(k),
                        );
                      }).toList(),
                    ),
                  )),

              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zrušit',
                    style: TextStyle(
                        color: Color(0xFFE8445A),
                        fontSize: 16,
                        fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _key({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}
