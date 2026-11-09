import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/features/print_job/guided_print_wizard.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

const String _storeLandscapeBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAlgAAAGQCAIAAAD9V4nPAAAWJ0lEQVR42u3d67Ne1V0H8L0fz4zvar2M0yJ1nDF1RqlvfOM7/wIF2upBa4MCCYGEQiH3e0IIkNtJICEpt3CncLhJO1ZHhltr5VqwtdRevCCQogbalHe22vgiLaTJyTnPbe+91vp9PpPptDPpyXPW/q3fd/32fp5z6k888cMKAKLqWQIAIpuorQEAJkIAMBECQLwgrCQhACZCAIjJM0IATIQAYCIEgJAToZEQABMhAESdCK0BACZCADARAkC8IPSTZQAwEQKAIASAeLxZBoDgE6GREAATIQBEnQitAQAmQgAwEQJAvCD0gXoATIQAEJRnhACYCAHARAgAISdCIyEAJkIAiDoRWgMATIQAEHUiNBICEDoIrQEAgbk1CoCJEABMhAAQciI0EgJgIgSAqBOhNQDARAgAJkIAiBeElSQEwEQIAFEnQgDyN/XrB2b/C1e8drFVmlF9xTM/tAoA2dk1V/LNbqlcFIQAMSNQHJ4YhEufFYQAGdj5oQPNffFlr8dNxHrZsz9SXgAp2/Gh/e38Q8tfXxxweX2gHkAKdvBvJTQRLjcRAiRpe3extCLSaFgvf04QAqSXgqd3PJyteCNKFtYrBCFAYradnsQtypUxstAzQgApmPoraXYiXGkiBEjGtellz6rS50ITIYAUzO9VjXMiXPW8iRCge9f8WtJ5s/pQsXOhiRBACpbwcoefCFebCAE6dXU+GbOmxLnQRAggBct8tX3yi3kBGEB5qVGvecGtUYBubD0tywFr7XeLukFarxWEAF246rSMbzOuKygLPSMEILR6nYkQoHVbTsv+XSfrSxkKJ2rvlgFgiEGqlPhwaxSA2Im+4UW3RgFatfmDhXwab+ObJdwdNRECEHsi3GgiBGjRpg8W9cNZNuU/FE5U3iwDwPDzVPbfgR+xBkDkHPSMEIDYTIQAmAgBaMWGD+z3HaU3ERoJARhlKMw8R0yEAITmGSEAo02Emb9+EyEAJkIAiDoR+skyAIROQhMhALEnQkEIQOQg9GYZAELzgXoARpsIfaAegD5de3ix7yi9iVBhAjD0OJj/t2AiBCA0EyEAoSdCH6gHIHQS1tu/+iPXEaBNy3+lkN9KuOOtEt774xkhALFn2h0mQoDWLct/KNz5ViEfBTERAhCanywDwDCKiQ8TIUAHdr292OtPZiJUjwAMOg6W9L1Mfe1/XVGATlz+yzfk+LJ3v72kqFCf+idBCNBdFv5SZlm4+3tLCrsEbo0CMMj8VNx35M0yAF3ak9WAtae4cbCqqnqPW6MAXbsshxuk15WYgiZCABkTOgWrqqqv+7qJECAJl/5ionPh9d9fUvCymwgB5E3cFKyqqr7eRAiQkk+lNBfuLT0FTYQAyUkneyKkYFVV9V4TIUB6Lul6LtwXIwWrqqr3viIIAZLMwvd3loX7jiyJs871PkEIkLAl7cbhDZEi8BjPCAGS1mYyBUzBqqrqG0yEADlY3ORouD9kBApCgOiJGDn/3gvC/d8QhAD5ufgXRorDAz8QgT8NwgOCECB/F82Vi5+RfIIQAE7mF/MCEDsIK0kIgIkQAGLygXoATIQAYCIEgJAToZEQABMhAESdCK0BdOrz+3b/0SWXWwcwEULQFHz3P4FO1Ld+049Yg2587mfz70xzIXQThN8ShNBFCu6dYQo881OyEFoPwoOCEFr36N5T3gs9SxZCuzwjhIRSEOhgIrzNRAgt+qs+UvBsQyG0GYS3f1sQQkseub7fWfCjl8pCaIlbo5BcCg76l4GRJsI7TITQvIeHCraPmQvBRAhhU3CU/yMwwER4p4kQmvTQyGH2cXMhNGmi8sNGIfko/fhlshAaC0I5CM158Lrx3Nu0T6E5nhFC6ik43i8FnHjQvPs7nhHC+D3QQHT9iRukYCKEsCnY3JeF6BPhPf9iIoRxmt7TbFxNftpcCCZCiJqC7fwTEGsivNdECGNyf4sRdY65EEyEhfU1VIvihE74HOEp3bdn97W286eO3vRXLS2zeWE8W+m+f/0/q3Cyz+6eOv5//tnlV1gT+qyWNqlMGJ1bo6l3OtSGyoRmJ8L7TYQnufcUzeUTTt/0VyotU5lgIiywtaFUFC20NBFO/5uJ8D33TM3RUP78Ckdv+iqV9ilOMBG20doSbH9IQcUJI02ED5gIq6qqqrsHaSKfdPRWKqlSnGAi1AoJfekVJwzKB+qrqqruGrx33D01Nd/RW50kyaaGwbbMg/8e/dboXbuG727zl8pCdZIilQkDBOFDsYPwzpG727k6jjpJksqEPoV+RjiW7pZjiyTCJVaZ0O9E+HDUifCOsbaJv3D6VidJUplgIoS4KVjGtwCNT4SPvBpxIrx95/i7w18uc/RWJ4lSnGAibKO7FdM0Ke+CKk6YRbjPEd7WZEe4fefUeY7e6iRJPlwIp9wdj0a6NXqwle52vixUJ0lSmXCKIPyPKEF4cEd73e385TqOOkkyC1UmnByEnwsThLe22+Au0HEUSZJUJpwgyptl2m9wEVqqIvFtQgkT4ecDTIS3dLfzFzh9K5IkqUwINBF22+BucfpWJL5lSNtEXfS7qm/e3v1ur71vXZGkmoULV5gLmXlThKoNP2JNn3V1gBM3RaitUf/1a8U+I7wppQt5oaO3CkmSymSWHRGkPHpxrqjXgytiHRioEoKUR/2FEifCG1O9eIucvlWIyiS3HVF8edRfeL20ILxxW9I9btFKHUeFqEwy2w5ll0f9N2UF4Wdy6HEX6TgqRGWS23YouDy8a1QvtvJYn4jXetDLXXB51H9b0ER4IKvrdLHTt/JQmWS4F8qrkJ5L6wXb+Vgr1zdyhRTyk2X2X5vlhfFDZ5SHyiTHjXBg29TiVeXMhfXfvZH9rdEbcm5zS1a5DaU8VCZZboRiiqTn6nr9Nj+WztWMXCT1Y5lPhPuKuBKXOH2rDZVJnruggCKpHzuUcRDuu6acTnfJah1HbahMstwFuRdJr66qTP8U1un2XTOV77VI8A/JVubFi85Rny20xzY7ZO7tK9dnhHtLPO/vNcRYydLX86JF57z7n5RU/1lvuvrxDG+NXl90m7vUnSjlUWJlLjop/G688X6rWlj9Z9q+8gvCCG1OFiqPwspy0alHQHFYWPHn2L7qJ76bWRBed3WITnfZGlmoNgopywsvnONG6E03ycKiij+79tVzsdEIaG6R50zBPv8OGRV/dpuxfjKfiXBPsE73aUOh2si5MhcOGG83mwvLqvyMOlg2QRiz08lCtZFpZS4cdsgThyVVfi4drH4qhyDcHbjTXS4L1UZulblgtFudt8jCsso+/SZWP/VmDkG4NXSzu3ytLFQYeVTmgoXjedp3y82ysKiyT7yJ1U8nH4RTml1VXSELFUbylXnBwnG+5+VWWVhW2afcxOovvvnjlNdu19ZdSv+YpWuXWgSFkWxZnr9wsomvf/DmaYtcTM0n28R6LrxtYCkY8Vo0lIKNfmU177t4byL80n8mOhHuvEqzm8GyddHnQoWRlFdefa6Ff+W2W6bVvCYWLgg1O1moMKSgLCy14FNrYj2/Qyc7YX+zjBQMm4JVVZ23YPK8BZMKvpiAT2u1/z69iXCHfjeX5fGGQlURNgJPcHuA0TBItafTx+ovJxaE2/W7/qyIlIWqQgoe746iszBUtSfSx+ov/1dCQbh9i343SA2tD5GFqkIKzpCFt06rdn1sbEH4D8kE4Tb9bnArS89CVSEFZ3FnQXEYudQ772OpBKF+JwtVhQgMm4VKvds+1vM20QK2UJFvmdMapGA/zr1gUqnrY6P+eSaBifBadTCyVWXNhUpCCg7krjznQnWeSB+rn/3vjoPwmiuVwnis3lBIFioJETicuw9Oq3OtbAg9pVAMi0nkFKyq6pPnT+ayVe3WpFpZl88IlcLY+04BjwZVhRQcMQtVeBlZ2Op1ea6jW6NXq4aTms4Zv/H7o3/BNTnfIFUVUnAs7kn1HqkKT7Ob1c93FIRbFcQpms7ocbg2zyxUEiJwvO5NKQ6Vd8rdrH7hcAdBeNXm6DUxe9MZPQvXbcwsC5WEFGzCZ2+bVt65a6GbdRCEaqLPpjNiHGaUhUpCChachco7/SysX2w3CLfErolBO86IWbg+hyzcok2IwIbd11EWqu0xarSbtRqEkctilI4zShwmnoU6hRQsNQ7VdkZZWH/lrfaC8MpNQStj9I4zShZu2JRoFoatBynYlftvn1bYWWuom7UXhDGLY4ztprAs1CykYJFZqLBzzML6pVaCcHO84mio1wwdh5sSyMJN+oUUTMYDY8pCVd1RMxlbQ6tffrvBINy0UQomloWbu8zCaPUgAjPIwjumVXXGWTimhlb/Y5NBuDFMiXTYawaNw80dZeFG/UIKJunBYbNQSSdi9J7WYBAGqZIUGk36WahlSMHC4lBJl5SF9VebCcINUjDtOLyyxSzcoGVIwRw81F8Wquc0jdLTGgnCCIWSZpdJMAt1DcVZUhaq5yKzsP7a98YchOs3FF4oiXeZgbJwy5XNZmHxxaA+y/PwndPqOV/D9bQxB6EUzC4Om8tCXUN9FhOHirnsLOyN9xfel91iMuoy/b/U9Rt2jbcGjv3RONRn1j527qRiztQQPW2cQbiu3HLJscX03xnHnoLrNA71mb+PnjupmDO1btAs/Pr3x3NrdO36MsulgBbTz23SrVvGdoO01EpQojGN+DtB6VA/be3s+ZNVVdWvjCMI15TY+wrrL3Pu56vHkYVrpKAqFYckY/a2dtb8yWP/paf3Bekvc35HMiy7CyoFNQSGa2tnzZ98NwWrqqq/MdpEuLq47ll2xc95sL1mhLlwtShVpeZC0nN8WzvzuPwThKGby+z7ebgslIIK1d4h5SycMQJ/EoT/fGT4IFy1TgqWuZ+vvWpp2EpQpYjDaHtn+CAspvdFbi6z7Of+s1AKKlR7h6w3Tv3NoYJwpRQMsJ+39ZGFK6WgQrV3yHzXDBOEZfQ+naWfLT17FkpBtWrjWIQCtsxEbY2oqldefW7GLT1LeayQgmrVBXr1OXFYwK6pv/WDwSbCFWt3RVuj4Cfc7VuXllcGahWjoS3zXhB+e5AgXJ5z+9NWht7SO342C5dLQeWKLCxovwwQhPm2Pz1ljFkoBZUrsrCwLVN/p78gXCYFw+/qnVuXLpOCyhVxWNx+qX/r0afn/Eu//djzeootjYrFxilys0wcPXrUMjH7MtrVKpZBr6Zdk9FOqT/8yFOz/43fefwFy4RdrWKxa0rdLHMEYV4pqKHY2DY2do2dMqhedfToqf5IQSyy9cRV7nwBm17D+sMPPznzLPjEi+oMJ1xFi11T/Dap5z00QxCe8eSLlgkbW91iy0TYJhNVddQyMdz629jqlkEvvV2T4B6p5z34xInHlqe+YplwzlW62DJBNkhPCuKKtLNKFgpbJs1lqec98Ph7Kfj0S5YJ51yli/0SaoPU86Z/EoRnfPEly4S9rXqxZaLtjvo3px+vquojUhB7W+liv4TcHT/9QH2qK6WVKHGLQHPe6b2hVHzLvaqqPvKll0Ug9rZvHwUTs7f/3B984HfVBE04fOTQ4SOHfvX9p2tqJOt/6nd+/uj77Jd29sXhI4f6HNNbvigTOghNX9M4j0AUcF6O3Rd9p/fG+358uv0SeV/0LBYtXNkIF1cBo5Ay/XZ6iazU6IuVwkNvwuaEFEQ5jaWxvzumt/lSJ1xvWr7chd35UcPYLLlvip7FojkzHutKuu5qGAVWwGvudbVS412sTqZpgueHFCzmlJZy68iozPJ9N8CEi0qH2zvf26QqmTaLLfGdMq7tcMLppLV3807kuFhkdOKevZpzfLN47mWc1KcFyP3gWEZX77W2WFKQAmpDGaP8ytsOvQIWK5d7/eS+owrY9p6mn6pRdLsm/f/riRRhYbPNRNOLpcUzULWkeadUJZNUNXa4TYrcC73mFkvvcOIe4qydYNmoZFIb0ztpsE3/ox2O6b2G1ktxU8YpSjGT8k6xEVIMwvZbWGr3+ilp4xW2+T1Nt01yP5g2ZCKj65FLr/He9DEWVVfPQtRz2Zu0pM3b3DaJswt61ouUx/SunoW4iGQ0pjexTULtgt7oi6VrnFDHbjplnUzqmeDbpJOuPsuYnnoQahm0ucmHrrdnXnvIqc7TdFlosBlzECayXt0eIihpNHSqI/IeCX5vr2e9yOt0MmgFHhsHZx8KlXQ6ddLtv9vyq2poTB90j6j/3qDrawP3U9NG0oxGQ1VN2D2S+L291trpxBjXFFre5yO+azxOVaf2gYF+fjMJje4RLX2wiTDZe6FJ3eKgq30+e3Eef0f0hLujGgEx58JZdk3YttlzZG4olWOWVCenkyGqVGGT8pje3HlR5c9oYvRO4f4GiRx7+7lTqhEkFQAtd49+MqbUhjZn5Ue+X93TLCh1q5/8TtE+P1BoTIfUTietBuGgTwS7+lkqKazdnP+QFtNJFjrG4XTCkEGog0Q7ZBV8OlHJGVWmpp/adQl4RXqjNA6fnCNZp7oLqlD1+jTPkXQZhAbBUje8zWxMrxJ7iIAxPc3TSU8RNHohtRiYcztE2yZOJ8lNhA4RBe+xsHspwdOJMR0KDEJwOgFjetwgtHb9f79trom35BnTkz2ddDumD/r1bRwTITidQPmnk1yWoukF6Vm74qtK00/turgiZNFO4xRqz9o52TmdYEwnMrdGocwx3ekEp5OmgtDa5VjTxnRVGvmiDPdlm3gxTicJXpT8JsKk1g6cTiDiREiCJ7tux3SnEzCmBwpCa4fTidNJvhclr/rUS02EOJ0AJBaETnZOdjidBNmtZV+dzpt5ahelp6AVdBkXxenEkRHKD0JwOnFkNJg6nXQWhNZOlwEwEVJCJDudOG7HuSijfx2HV0GooHFRwJ4tvJmbCBU0uozycGQ0EaKgXRRcFAShgtZlcFFQogFLtBfk+mk0LgpKVIm6KMMEoUpKcDVcFBfFy1CiLkq4iRAAGlLP+8M/tgoAhGUiBEAQAoAgBABBCACCEAAEIQAIQgAQhAAgCAFAEAKAIAQAQQgAghAABCEACEIAEIQAIAgBQBACgCAEgAxMvPN7Z1sFAOIGYXXUIgAQl1ujAESfCI2EAJgIASDmRGggBCB0EFbeLQNA6CCUgwAE5hkhACZCAAgchJIQgMBBKAYBCD4RWgQAIgehJATARAgAMfn4BADRJ0IjIQCBg1AMAhB8IrQIAIQOQkkIQFzeLANA9InQIgBgIgSAmBPhUc8IATARAkDQidAzQgBiB6EkBMBECACCEADiBeFRSQiAiRAAYvLxCQCiT4RGQgBMhAAQdSK0CAAEDkLvGgXARAgAghAA4vFmGQCiT4RGQgBMhAAQcyI0EAIQOgj9PkIAYgehHAQgMM8IAYg+ERoJAQgdhBYBgMBBKAcBCD4RikIA4vJmGQCiT4QWAQATIQBEnQiNhAAEDkIxCEDwidAiABA6CCUhAHF5swwA0SdCiwBA5CCUhABEDkKPCAGIzDNCAGJPhN41CoCJEADiToQWAYC4/h/r7G+Fh/7xqQAAAABJRU5ErkJggg==';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 home with a selected photo', (WidgetTester tester) async {
    final _Fixture fixture = _fixture();

    await _pump(
      tester,
      HomeScreen(
        imagePickerGateway: _StoreImagePicker(fixture.image),
        imageProcessor: fixture.processor,
        localeOverride: const Locale('en'),
        onLocaleChanged: (_) {},
      ),
    );
    await tester.tap(find.byKey(const Key('choose-photo')));
    await _pumpUi(tester);

    expect(find.text('Print photos at the exact size'), findsOneWidget);
    await _capture(binding, tester, '01-home-selected');
  });

  testWidgets('02 real size step with 10 x 15 preset', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 1 of 4'), findsOneWidget);
    expect(find.text('10 × 15 cm'), findsOneWidget);
    await _capture(binding, tester, '02-size-10x15');
  });

  testWidgets('03 real focused framing editor', (WidgetTester tester) async {
    final _Fixture fixture = _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('open-framing-focus')));
    await _pumpUi(tester);

    expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);
    expect(find.text('Adjust framing'), findsOneWidget);
    await _capture(binding, tester, '03-framing-focus');
  });

  testWidgets('04 real A4 sheet step', (WidgetTester tester) async {
    final _Fixture fixture = _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 3 of 4'), findsOneWidget);
    expect(find.text('A4'), findsOneWidget);
    await _capture(binding, tester, '04-sheet-a4');
  });

  testWidgets('05 real 10 x 15 photo-paper sheet', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await _configureTenByFifteen(tester);

    expect(find.text('Photo 10 × 15 cm'), findsOneWidget);
    await _capture(binding, tester, '05-sheet-10x15');
  });

  testWidgets('06 real wizard review step', (WidgetTester tester) async {
    final _Fixture fixture = _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await _configureTenByFifteen(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 4 of 4'), findsOneWidget);
    expect(find.textContaining('100 × 150 mm'), findsWidgets);
    await _capture(binding, tester, '06-review');
  });
}

_Fixture _fixture() {
  final Uint8List photoBytes = base64Decode(_storeLandscapeBase64);
  final SelectedImage image = SelectedImage(
    bytes: photoBytes,
    displayName: 'photo-cut-demo.png',
  );
  return _Fixture(
    image: image,
    processor: _StoreImageProcessor(photoBytes: photoBytes),
  );
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const PhotoCutScrollBehavior(),
      locale: const Locale('en'),
      supportedLocales: PhotoCutLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        PhotoCutLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
  await _pumpUi(tester);
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> _configureTenByFifteen(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('size-preset-10x15')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-paper-photo-10x15')));
  await _pumpUi(tester);

  for (int i = 0; i < 7; i += 1) {
    await tester.tap(find.byKey(const Key('copies-minus')));
    await tester.pump();
  }
  await _pumpUi(tester);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await _pumpUi(tester);
  await binding.takeScreenshot(name);
}

final class _Fixture {
  const _Fixture({required this.image, required this.processor});

  final SelectedImage image;
  final _StoreImageProcessor processor;
}

final class _StoreImagePicker implements ImagePickerGateway {
  const _StoreImagePicker(this.image);

  final SelectedImage image;

  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    return ImageSelectionSuccess(image);
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    return const ImageSelectionCancelled();
  }
}

final class _StoreImageProcessor implements ImageProcessor {
  const _StoreImageProcessor({required this.photoBytes});

  final Uint8List photoBytes;

  static final SourceImageSize _size = SourceImageSize(
    widthPixels: 600,
    heightPixels: 400,
  );

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => _size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: photoBytes, size: _size);
  }
}
