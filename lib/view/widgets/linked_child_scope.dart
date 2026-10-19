import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth/auth_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/network/network_api_services.dart';
import '../../utils/app_url.dart';

/// A module is only created after a parent explicitly selects a linked child.
class LinkedChildScope extends StatefulWidget {
  final Widget Function(String? admissionNo) builder;
  const LinkedChildScope({super.key, required this.builder});
  @override
  State<LinkedChildScope> createState() => _LinkedChildScopeState();
}

class _LinkedChildScopeState extends State<LinkedChildScope> {
  List? _children;
  String? _selected, _error;
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (context.read<AuthBloc>().state.user?.role != UserRole.parent) return;
    setState(() => _error = null);
    try {
      final data = await NetworkApiService().getApi(
        '${AppUrl.baseUrl}/mobile/portal/context',
      );
      if (!mounted) return;
      final children = data['children'] as List;
      final args = ModalRoute.of(context)?.settings.arguments;
      final requested = args is Map ? args['admissionNo']?.toString() : null;
      setState(() {
        _children = children;
        _selected = children.any((c) => c['admissionNo'] == requested)
            ? requested
            : children.length == 1
            ? children.first['admissionNo'].toString()
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<AuthBloc>().state.user?.role != UserRole.parent) {
      return widget.builder(null);
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select child')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_children == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Child'),
              items: _children!
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c['admissionNo'].toString(),
                      child: Text('${c['name']} (${c['admissionNo']})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
        ),
        Expanded(
          child: _selected == null
              ? const Center(
                  child: Text('Select a linked child to view records.'),
                )
              : KeyedSubtree(
                  key: ValueKey(_selected),
                  child: widget.builder(_selected),
                ),
        ),
      ],
    );
  }
}
