// import 'package:app_ui/app_ui.dart';
// import 'package:flutter/material.dart';

// class AuthProviderSignInButton extends StatelessWidget {
//   const AuthProviderSignInButton({
//     required this.provider,
//     required this.onPressed,
//     this.enabled = true,
//     this.isInProgress = false,
//     super.key,
//   });

//   final AuthProvider provider;
//   final VoidCallback onPressed;
//   final bool enabled;
//   final bool isInProgress;

//   @override
//   Widget build(BuildContext context) {
//     final effectiveIcon = switch (provider) {
//       AuthProvider.google => VectorGraphic(
//           loader: AssetBytesLoader(
//             Assets.icons.google.path,
//             packageName: 'app_ui',
//           ),
//           width: 24,
//         ),
//     };
//     final icon = SizedBox.square(
//       dimension: 24,
//       child: effectiveIcon,
//     );
//     return Container(
//       constraints: BoxConstraints(
//         minWidth: switch (context.screenWidth) {
//           > 600 => context.screenWidth * .6,
//           _ => context.screenWidth,
//         },
//       ),
//       margin: const EdgeInsets.only(bottom: AppSpacing.md),
//       child: FilledButton.tonalIcon(
//         onPressed: !enabled || isInProgress ? null : onPressed,
//         label: const Text(
//           'Sign in with Google',
//           overflow: TextOverflow.ellipsis,
//         ),
//         icon: isInProgress
//             ? Transform.scale(
//                 scale: .6,
//                 child: const CircularProgressIndicator(),
//               )
//             : icon,
//       ),
//     );
//   }
// }

// enum AuthProvider {
//   google('Google');

//   const AuthProvider(this.value);

//   final String value;
// }
