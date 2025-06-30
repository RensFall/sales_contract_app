import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:signature/signature.dart";
import "dart:convert";
import "dart:typed_data";
import "package:intl/intl.dart";
import "../../model/contract_model.dart";
import "../../services/auth_service.dart";
import "../../services/contract_service.dart";
import "../../widget/contract_preview.dart";

class SignatureScreen extends StatefulWidget {
  final ContractModel contract;

  const SignatureScreen({super.key, required this.contract});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _hasAgreed = false;
  bool _isSigning = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final currentUserId = auth.currentUser?.uid;
    final hasAlreadySigned =
        widget.contract.signatures.containsKey(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text("sign_contract".tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSignatureInfo(context),
          ),
        ],
      ),
      body: hasAlreadySigned
          ? _buildAlreadySignedView()
          : _buildSigningView(auth),
    );
  }

  Widget _buildSigningView(AuthService auth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ContractPreview(contract: widget.contract),
          _buildAgreementSection(),
          if (_hasAgreed) _buildSignatureSection(auth),
          if (!_hasAgreed) _buildAgreementPrompt(),
        ],
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                "contract_agreement".tr(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _hasAgreed,
            onChanged: (value) => setState(() => _hasAgreed = value!),
            title: Text(
              "i_agree_terms".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "acknowledgment_text".tr(),
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(AuthService auth) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey, blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.draw, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    "digital_signature".tr(),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSignerInfo(auth),
              const SizedBox(height: 16),
              Text("please_draw_signature".tr(),
                  style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 8),
              _buildSignaturePad(),
              const SizedBox(height: 12),
              _buildClearAndNoteRow(),
            ],
          ),
        ),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildSignerInfo(AuthService auth) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.person, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${"signing_as".tr()} ${auth.currentUser?.fullName ?? ""}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("ID: ${auth.currentUser?.idNumber ?? ""}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now()),
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSignaturePad() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Signature(
                controller: _signatureController,
                backgroundColor: Colors.white),
            if (_signatureController.isEmpty)
              Center(
                child: Text("sign_here".tr(),
                    style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearAndNoteRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => _signatureController.clear(),
          icon: const Icon(Icons.clear),
          label: Text("clear".tr()),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
        ),
        Text("signature_added_note".tr(),
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSigning ? null : _submitSignature,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isSigning
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("submit_signature".tr(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAgreementPrompt() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("read_accept_terms".tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAlreadySignedView() {
    final auth = context.read<AuthService>();
    final signedAt =
        widget.contract.signatures[auth.currentUser?.uid]?.signedAt;
    final signedDate =
        signedAt != null ? DateFormat("dd/MM/yyyy HH:mm").format(signedAt) : "";

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[600]),
            const SizedBox(height: 24),
            Text("already_signed".tr(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text("${"signed_on".tr()} $signedDate",
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text("go_back".tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignatureInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("digital_signature_info".tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("signature_legally_binding".tr(),
                style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            Text("by_signing".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...[
              "confirm_info_accurate",
              "agree_terms",
              "binding_agreement",
              "signature_recorded"
            ].map((key) => Text(key.tr())),
            const SizedBox(height: 16),
            Text("signature_includes".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...[
              "handwritten_signature",
              "date_time",
              "user_info",
              "agreement_confirmation"
            ].map((key) => Text(key.tr())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("understood".tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("please_sign".tr()), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSigning = true);

    try {
      final Uint8List? signatureData = await _signatureController.toPngBytes();
      if (signatureData == null) throw Exception("Failed to capture signature");

      final signatureBase64 = base64Encode(signatureData);

      await context.read<ContractService>().signContract(
            widget.contract.id,
            context.read<AuthService>().currentUser!.uid,
            signatureBase64,
            agreedToTerms: true,
          );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: Text("signature_submitted".tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("signature_recorded_msg".tr(),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("notify_all_signed".tr(),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("ok".tr()),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("${"error".tr()}: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }
}
