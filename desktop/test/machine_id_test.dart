import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/data/repositories/device_repository.dart';

void main() {
  const guid = '9188eaba-dbfd-4e70-a298-02c63b9a0144';

  test('PCs cloned from one Windows image (same MachineGuid) get different ids from their boards', () {
    final a = composeMachineId(machineGuid: guid, hardwareUuid: '4C4C4544-0042-3510-8051-B3C04F4D3332', installId: 'x');
    final b = composeMachineId(machineGuid: guid, hardwareUuid: '4c4c4544-0042-3510-8051-c7c04f4d3332', installId: 'x');
    expect(a, '$guid:4C4C4544-0042-3510-8051-B3C04F4D3332');
    expect(b, isNot(a));
  });

  test('a missing or placeholder board UUID falls back to this installation\'s id', () {
    for (final hw in [null, '', '00000000-0000-0000-0000-000000000000', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
        '03000200-0400-0500-0006-000700080009', 'not a uuid']) {
      expect(composeMachineId(machineGuid: guid, hardwareUuid: hw, installId: 'inst-1'), '$guid:i-inst-1', reason: '$hw');
    }
  });

  test('no MachineGuid: the board UUID (or install id) alone', () {
    expect(composeMachineId(hardwareUuid: '4C4C4544-0042-3510-8051-B3C04F4D3332', installId: 'x'),
        '4C4C4544-0042-3510-8051-B3C04F4D3332');
    expect(composeMachineId(installId: 'inst-2'), 'i-inst-2');
  });
}
