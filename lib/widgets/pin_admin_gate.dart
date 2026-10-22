import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'pin_admin_dialog.dart';

/// Buka halaman yang butuh hak admin.
///
/// Admin langsung masuk; non-admin harus memasukkan PIN Admin dulu (perilaku
/// sama dengan `_openProtected` lama di HomeView).
Future<void> openAdminMenu(
  BuildContext context,
  WidgetBuilder builder,
) async {
  final isAdmin =
      context.read<AuthViewModel>().currentUser?.isAdmin ?? false;
  if (!isAdmin) {
    final ok = await PinAdminDialog.verify(context);
    if (!ok) return;
  }
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: builder),
  );
}
