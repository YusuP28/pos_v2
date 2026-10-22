import 'package:flutter/material.dart';

/// Kartu menu yang dipakai di dashboard maupun halaman kategori.
///
/// [subtitle] opsional (halaman kategori), [locked] menampilkan ikon gembok
/// sebagai penanda menu yang butuh PIN admin.
class MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool locked;
  final EdgeInsetsGeometry margin;

  const MenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.locked = false,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.lock, size: 14, color: Colors.orange),
                )
              else if (subtitle != null)
                const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
