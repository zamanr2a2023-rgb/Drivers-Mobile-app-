import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/constants/app_assets.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// DR8 · Can’t find address
class CantFindAddressScreen extends StatelessWidget {
  const CantFindAddressScreen({
    super.key,
    this.args = const IncidentContextArgs(),
  });

  final IncidentContextArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IncidentColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IncidentHeader(
              title: 'Can’t find the address',
              subtitle: args.customerOrderSubtitle,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  IncidentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address the customer confirmed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: IncidentColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${args.address}\n${args.pin}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                            color: IncidentColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: IncidentOutlinedButton(
                          label: 'Call',
                          leading: const Icon(
                            Icons.call,
                            size: 18,
                            color: IncidentColors.textPrimary,
                          ),
                          onPressed: () =>
                              showIncidentSnack(context, 'Calling customer…'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: IncidentOutlinedButton(
                          label: 'Message',
                          leading: Image.asset(
                            AppAssets.incidentMessage,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RouteNames.dispatchCantReachChat,
                            arguments: args,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  IncidentOutlinedButton(
                    label: 'Ask dispatch to help locate',
                    textColor: IncidentColors.headerGreen,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.dispatchCantReachChat,
                      arguments: args,
                    ),
                  ),
                  const SizedBox(height: 10),
                  IncidentPrimaryButton(
                    label: 'Report wrong / unreachable address',
                    onPressed: () {
                      showIncidentSnack(
                        context,
                        'Wrong address reported to dispatch',
                      );
                      Navigator.maybePop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
