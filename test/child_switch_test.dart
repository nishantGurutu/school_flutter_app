import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/core/di/locator.dart';
import 'package:school_desk_app/data/repositories/school_repository.dart';
import 'package:school_desk_app/data/models/school_models.dart';
import 'package:school_desk_app/logic/school/school_bloc.dart';
import 'package:school_desk_app/logic/school/school_event.dart';

class PendingFees implements SchoolRepository {
 final requests=<String,Completer<List<FeeRecord>>>{};
 @override Future<List<FeeRecord>> getFees(String userId,{String? admissionNo}) {
  return requests.putIfAbsent(admissionNo!,()=>Completer<List<FeeRecord>>()).future;
 }
 @override dynamic noSuchMethod(Invocation invocation)=>super.noSuchMethod(invocation);
}
void main(){
 test('Late response for the previous child cannot overwrite selected child fees',() async {
  await getIt.reset();
  final repository=PendingFees();getIt.registerSingleton<SchoolRepository>(repository);
  final bloc=SchoolBloc();
  bloc.add(const FetchFeesRequested('parent',admissionNo:'A'));
  await Future<void>.delayed(Duration.zero);
  bloc.add(const FetchFeesRequested('parent',admissionNo:'B'));
  await Future<void>.delayed(Duration.zero);
  FeeRecord fee(String id)=>FeeRecord(id:id,title:id,amount:20,dueDate:DateTime(2026),status:FeeStatus.unpaid);
  repository.requests['B']!.complete([fee('B')]);
  await Future<void>.delayed(Duration.zero);
  expect(bloc.state.fees.single.id,'B');
  repository.requests['A']!.complete([fee('A')]);
  await Future<void>.delayed(Duration.zero);
  expect(bloc.state.fees.single.id,'B');
  await bloc.close();await getIt.reset();
 });
}
