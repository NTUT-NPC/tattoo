import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/services/campus_wifi/android_campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ios_campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_auto_reprovision.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('CampusWifiRepository', () {
    test('returns ready data with normal screen mode', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = _buildRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(),
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.status, Ntut8021xAssistantStatus.ready);
      expect(data.identity, '111360109');
      expect(data.password, 'portal-password');
      expect(data.screenMode, Ntut8021xScreenMode.normal);
      expect(data.capabilities.canProvisionNtut8021xSuggestion, isTrue);
    });

    test('android 11+ denied permission requires settings with optional compat save', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = _buildRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(
          capabilities: const (
            isSupported: true,
            androidSdkInt: 30,
            canOpenWifiSettings: true,
            canOpenWifiPanel: true,
            canProvisionNtut8021xSuggestion: true,
            canProvisionNtut8021xCompat: true,
            canProvisionNtut8021x: true,
            suggestionPermissionState: 'disallowed',
          ),
        ),
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.screenMode, Ntut8021xScreenMode.permissionRequired);
      expect(data.canProvisionAutomatically, isFalse);
      expect(data.canUseCompatMode, isTrue);
      expect(data.pendingPromptReason, isNull);
    });

    test(
      'android 10 denied permission requires settings without compat save',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);

        final repository = _buildRepository(
          authRepository: authRepository,
          platform: _FakeCampusWifiPlatform(
            capabilities: const (
              isSupported: true,
              androidSdkInt: 29,
              canOpenWifiSettings: true,
              canOpenWifiPanel: true,
              canProvisionNtut8021xSuggestion: true,
              canProvisionNtut8021xCompat: false,
              canProvisionNtut8021x: true,
              suggestionPermissionState: 'disallowed',
            ),
          ),
        );

        final data = await repository.getNtut8021xAssistantData();

        expect(data.screenMode, Ntut8021xScreenMode.permissionRequired);
        expect(data.canProvisionAutomatically, isFalse);
        expect(data.canUseCompatMode, isFalse);
      },
    );

    test(
      'consumePendingImmediatePrompt returns prompt from local state',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);

        final prefs = SharedPreferencesAsync();
        final stateStore = Ntut8021xStateStore(prefs);
        await stateStore.setPendingCompatPrompt(
          reason: Ntut8021xStoredPendingPromptReason.credentialChanged,
          immediate: true,
        );

        final repository = _buildRepository(
          authRepository: authRepository,
          platform: _FakeCampusWifiPlatform(),
          stateStore: stateStore,
        );

        final prompt = await repository.consumePendingImmediatePrompt();

        expect(prompt, isNotNull);
        expect(prompt!.reason, Ntut8021xPendingPromptReason.credentialChanged);
        expect(prompt.identity, '111360109');
        expect(prompt.password, 'portal-password');
      },
    );

    for (final mode in [
      Ntut8021xStoredProvisioningMode.compat,
      Ntut8021xStoredProvisioningMode.direct,
    ]) {
      test(
        'denied suggestion permission preserves and consumes $mode credential update',
        () async {
          final authRepository = _FakeAuthRepository(
            localUser: _testUser,
            credentials: (username: '111360109', password: 'portal-password'),
          );
          addTearDown(authRepository.close);
          final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
          await stateStore.markProvisioned(mode: mode);
          await stateStore.setPendingCompatPrompt(
            reason: .credentialChanged,
            immediate: true,
          );
          final repository = _buildRepository(
            authRepository: authRepository,
            stateStore: stateStore,
            platform: _FakeCampusWifiPlatform(
              capabilities: const (
                isSupported: true,
                androidSdkInt: 30,
                canOpenWifiSettings: true,
                canOpenWifiPanel: true,
                canProvisionNtut8021xSuggestion: true,
                canProvisionNtut8021xCompat: true,
                canProvisionNtut8021x: true,
                suggestionPermissionState: 'disallowed',
              ),
            ),
          );

          final data = await repository.getNtut8021xAssistantData();

          expect(
            data.pendingPromptReason,
            Ntut8021xPendingPromptReason.credentialChanged,
          );
          expect(data.showImmediatePromptCandidate, isTrue);
          final pendingState = await stateStore.read();
          expect(
            pendingState.pendingCompatPromptReason,
            Ntut8021xStoredPendingPromptReason.credentialChanged,
          );
          expect(pendingState.pendingImmediatePrompt, isTrue);

          final prompt = await repository.consumePendingImmediatePrompt();

          expect(prompt, isNotNull);
          expect(
            prompt!.reason,
            Ntut8021xPendingPromptReason.credentialChanged,
          );
          expect(prompt.identity, '111360109');
          expect(prompt.password, 'portal-password');
          final consumedState = await stateStore.read();
          expect(consumedState.lastProvisioningMode, mode);
          expect(
            consumedState.pendingCompatPromptReason,
            Ntut8021xStoredPendingPromptReason.credentialChanged,
          );
          expect(consumedState.pendingImmediatePrompt, isFalse);
          expect(await repository.consumePendingImmediatePrompt(), isNull);
        },
      );
    }

    for (final consumeFirst in [false, true]) {
      test(
        'denied suggestion permission clears stale fallback (consume first: $consumeFirst)',
        () async {
          final authRepository = _FakeAuthRepository(
            localUser: _testUser,
            credentials: (username: '111360109', password: 'portal-password'),
          );
          addTearDown(authRepository.close);
          final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
          await stateStore.setPendingCompatPrompt(
            reason: .suggestionFallbackRequired,
            immediate: true,
          );
          final repository = _buildRepository(
            authRepository: authRepository,
            stateStore: stateStore,
            platform: _FakeCampusWifiPlatform(
              capabilities: const (
                isSupported: true,
                androidSdkInt: 30,
                canOpenWifiSettings: true,
                canOpenWifiPanel: true,
                canProvisionNtut8021xSuggestion: true,
                canProvisionNtut8021xCompat: true,
                canProvisionNtut8021x: true,
                suggestionPermissionState: 'disallowed',
              ),
            ),
          );

          if (consumeFirst) {
            expect(await repository.consumePendingImmediatePrompt(), isNull);
          }
          final data = await repository.getNtut8021xAssistantData();

          expect(data.pendingPromptReason, isNull);
          expect(data.showImmediatePromptCandidate, isFalse);
          final state = await stateStore.read();
          expect(state.pendingCompatPromptReason, isNull);
          expect(state.pendingImmediatePrompt, isFalse);
          expect(await repository.consumePendingImmediatePrompt(), isNull);
        },
      );
    }

    test(
      'suggestion rejection never automatically saves a system network',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);
        final prefs = SharedPreferencesAsync();
        final stateStore = Ntut8021xStateStore(prefs);

        final platform = _FakeCampusWifiPlatform(
          provisioningResult: const (
            status: 'approvalRejected',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: 1,
            approvalStatus: null,
            compatResultCode: null,
            compatNetworkResultCodes: <int>[],
            suggestionPermissionState: 'disallowed',
            message: null,
          ),
          compatResult: const (
            status: 'compatSuccess',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: null,
            approvalStatus: null,
            compatResultCode: 0,
            compatNetworkResultCodes: <int>[0],
            suggestionPermissionState: null,
            message: null,
          ),
        );
        final repository = _buildRepository(
          authRepository: authRepository,
          stateStore: stateStore,
          platform: platform,
        );

        final result = await repository.provisionNtut8021x();

        expect(result.status, Ntut8021xProvisioningStatus.approvalRejected);
        expect(platform.provisionCallCount, 1);
        expect(platform.compatCallCount, 0);
        expect(result.pendingPromptReason, isNull);
        final state = await stateStore.read();
        expect(
          state.lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.none,
        );
        expect(state.pendingCompatPromptReason, isNull);
        expect(state.pendingImmediatePrompt, isFalse);
        expect(
          await prefs.getBool(ntut8021xAutoReprovisionPreferenceKey),
          isNot(true),
        );
        expect(await repository.consumePendingImmediatePrompt(), isNull);
      },
    );

    test('compat already-exists keeps the pending prompt active', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
      await stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.compat,
      );

      final repository = _buildRepository(
        authRepository: authRepository,
        stateStore: stateStore,
        platform: _FakeCampusWifiPlatform(
          compatResult: const (
            status: 'compatAlreadyExists',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: null,
            approvalStatus: null,
            compatResultCode: 0,
            compatNetworkResultCodes: <int>[1],
            suggestionPermissionState: null,
            message: null,
          ),
        ),
      );

      final result = await repository.saveNtut8021xToSystem(
        pendingPromptReason: Ntut8021xPendingPromptReason.credentialChanged,
      );

      final storedState = await stateStore.read();
      expect(result.status, Ntut8021xProvisioningStatus.compatAlreadyExists);
      expect(result.isSuccess, isFalse);
      expect(
        result.pendingPromptReason,
        Ntut8021xPendingPromptReason.credentialChanged,
      );
      expect(
        storedState.pendingCompatPromptReason,
        Ntut8021xStoredPendingPromptReason.credentialChanged,
      );
      expect(
        storedState.lastProvisioningMode,
        Ntut8021xStoredProvisioningMode.compat,
      );
    });

    test(
      'iOS configuration clears pending updates only after acceptance',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'new-password'),
        );
        addTearDown(authRepository.close);
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        await stateStore.setPendingCompatPrompt(
          reason: .credentialChanged,
          immediate: true,
        );
        final platform = _FakeCampusWifiPlatform(
          capabilities: _iosCapabilities,
          provisioningResult: _iosResult('configured'),
        );
        final repository = _buildRepository(
          authRepository: authRepository,
          stateStore: stateStore,
          platform: platform,
          provisioner: IosCampusWifiProvisioner(
            platform: platform,
            stateStore: stateStore,
          ),
        );

        final data = await repository.getNtut8021xAssistantData();
        expect(data.canProvisionAutomatically, isTrue);
        expect(data.canUseCompatMode, isFalse);
        expect(data.capabilities.isLegacyAndroidManualOnly, isFalse);
        final result = await repository.provisionNtut8021x();
        expect(result.status, Ntut8021xProvisioningStatus.configured);
        expect(result.isSuccess, isTrue);
        expect(result.lastProvisioningMode, Ntut8021xProvisioningMode.direct);
        final state = await stateStore.read();
        expect(
          state.lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.direct,
        );
        expect(state.pendingCompatPromptReason, isNull);
        expect(state.pendingImmediatePrompt, isFalse);
        expect(platform.provisionCallCount, 1);
        expect(platform.compatCallCount, 0);
      },
    );

    for (final (wireStatus, expectedStatus) in [
      ('cancelled', Ntut8021xProvisioningStatus.cancelled),
      ('alreadyAssociated', Ntut8021xProvisioningStatus.alreadyAssociated),
      ('failed', Ntut8021xProvisioningStatus.failed),
    ]) {
      test('iOS $wireStatus preserves the pending credential update', () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'new-password'),
        );
        addTearDown(authRepository.close);
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        await stateStore.markProvisioned(mode: .direct);
        await stateStore.setPendingCompatPrompt(
          reason: .credentialChanged,
          immediate: false,
        );
        final platform = _FakeCampusWifiPlatform(
          capabilities: _iosCapabilities,
          provisioningResult: _iosResult(wireStatus),
        );
        final repository = _buildRepository(
          authRepository: authRepository,
          stateStore: stateStore,
          platform: platform,
          provisioner: IosCampusWifiProvisioner(
            platform: platform,
            stateStore: stateStore,
          ),
        );

        final result = await repository.provisionNtut8021x();
        expect(result.status, expectedStatus);
        expect(result.isSuccess, isFalse);
        expect(platform.provisionCallCount, 1);
        expect(platform.compatCallCount, 0);
        final state = await stateStore.read();
        expect(
          state.lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.direct,
        );
        expect(
          state.pendingCompatPromptReason,
          Ntut8021xStoredPendingPromptReason.credentialChanged,
        );
        expect(
          (await repository.getNtut8021xAssistantData())
              .canProvisionAutomatically,
          isTrue,
        );
      });
    }

    test('iOS does not offer provisioning without saved credentials', () async {
      final authRepository = _FakeAuthRepository(localUser: _testUser);
      addTearDown(authRepository.close);
      final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
      final platform = _FakeCampusWifiPlatform(capabilities: _iosCapabilities);
      final repository = _buildRepository(
        authRepository: authRepository,
        platform: platform,
        stateStore: stateStore,
        provisioner: IosCampusWifiProvisioner(
          platform: platform,
          stateStore: stateStore,
        ),
      );
      final data = await repository.getNtut8021xAssistantData();
      expect(data.status, Ntut8021xAssistantStatus.credentialsMissing);
      expect(data.canProvisionAutomatically, isFalse);
      expect(
        (await repository.provisionNtut8021x()).status,
        Ntut8021xProvisioningStatus.unsupportedPlatform,
      );
      expect(platform.provisionCallCount, 0);
      expect(platform.compatCallCount, 0);
    });

    test(
      'iOS ignores Android SDK metadata and suggestion denial',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'new-password'),
        );
        addTearDown(authRepository.close);
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        await stateStore.markProvisioned(mode: .direct);
        await stateStore.setPendingCompatPrompt(
          reason: .credentialChanged,
          immediate: true,
        );
        final platform = _FakeCampusWifiPlatform(
          capabilities: const (
            isSupported: true,
            androidSdkInt: 34,
            canOpenWifiSettings: true,
            canOpenWifiPanel: true,
            canProvisionNtut8021xSuggestion: true,
            canProvisionNtut8021xCompat: true,
            canProvisionNtut8021x: true,
            suggestionPermissionState: 'disallowed',
          ),
          provisioningResult: _iosResult('cancelled'),
          compatResult: _iosResult('cancelled'),
        );
        final repository = _buildRepository(
          authRepository: authRepository,
          platform: platform,
          stateStore: stateStore,
          provisioner: IosCampusWifiProvisioner(
            platform: platform,
            stateStore: stateStore,
          ),
        );

        final data = await repository.getNtut8021xAssistantData();
        expect(data.status, Ntut8021xAssistantStatus.ready);
        expect(data.screenMode, Ntut8021xScreenMode.normal);
        expect(data.canProvisionAutomatically, isTrue);
        expect(data.canUseCompatMode, isFalse);
        expect(
          data.pendingPromptReason,
          Ntut8021xPendingPromptReason.credentialChanged,
        );

        final result = await repository.provisionNtut8021x();
        expect(result.status, Ntut8021xProvisioningStatus.cancelled);
        expect(result.isSuccess, isFalse);
        final saveResult = await repository.saveNtut8021xToSystem(
          pendingPromptReason: .credentialChanged,
        );
        expect(saveResult.status, Ntut8021xProvisioningStatus.cancelled);
        expect(platform.provisionCallCount, 1);
        expect(platform.compatCallCount, 1);

        final state = await stateStore.read();
        expect(
          state.lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.direct,
        );
        expect(
          state.pendingCompatPromptReason,
          Ntut8021xStoredPendingPromptReason.credentialChanged,
        );
        expect(state.pendingImmediatePrompt, isTrue);
        final refreshedData = await repository.getNtut8021xAssistantData();
        expect(refreshedData.canProvisionAutomatically, isTrue);
        expect(
          refreshedData.pendingPromptReason,
          Ntut8021xPendingPromptReason.credentialChanged,
        );
      },
    );

    test(
      'Android without suggestion or compat support never uses direct apply',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);
        final platform = _FakeCampusWifiPlatform(
          capabilities: const (
            isSupported: true,
            androidSdkInt: 34,
            canOpenWifiSettings: true,
            canOpenWifiPanel: true,
            canProvisionNtut8021xSuggestion: false,
            canProvisionNtut8021xCompat: false,
            canProvisionNtut8021x: true,
            suggestionPermissionState: 'allowed',
          ),
          provisioningResult: _iosResult('configured'),
        );
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        final repository = _buildRepository(
          authRepository: authRepository,
          platform: platform,
          stateStore: stateStore,
        );

        final data = await repository.getNtut8021xAssistantData();
        expect(data.screenMode, Ntut8021xScreenMode.manualOnly);
        expect(data.canProvisionAutomatically, isFalse);
        expect(data.canUseCompatMode, isFalse);
        expect(
          (await repository.provisionNtut8021x()).status,
          Ntut8021xProvisioningStatus.unsupportedPlatform,
        );
        expect(
          (await repository.saveNtut8021xToSystem()).status,
          Ntut8021xProvisioningStatus.unsupportedPlatform,
        );
        expect(platform.provisionCallCount, 0);
        expect(platform.compatCallCount, 0);
        expect(
          (await stateStore.read()).lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.none,
        );
      },
    );

    for (final isSupported in [false, true]) {
      test(
        'iOS without native apply stays manual when supported=$isSupported',
        () async {
          final authRepository = _FakeAuthRepository(
            localUser: _testUser,
            credentials: (username: '111360109', password: 'new-password'),
          );
          addTearDown(authRepository.close);
          final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
          await stateStore.setPendingCompatPrompt(
            reason: .credentialChanged,
            immediate: true,
          );
          final platform = _FakeCampusWifiPlatform(
            capabilities: (
              isSupported: isSupported,
              androidSdkInt: null,
              canOpenWifiSettings: false,
              canOpenWifiPanel: false,
              canProvisionNtut8021xSuggestion: false,
              canProvisionNtut8021xCompat: false,
              canProvisionNtut8021x: false,
              suggestionPermissionState: 'unknown',
            ),
            provisioningResult: _iosResult('configured'),
          );
          final repository = _buildRepository(
            authRepository: authRepository,
            platform: platform,
            stateStore: stateStore,
            provisioner: IosCampusWifiProvisioner(
              platform: platform,
              stateStore: stateStore,
            ),
          );

          final data = await repository.getNtut8021xAssistantData();
          expect(
            data.status,
            isSupported
                ? Ntut8021xAssistantStatus.ready
                : Ntut8021xAssistantStatus.unsupportedPlatform,
          );
          expect(data.screenMode, Ntut8021xScreenMode.manualOnly);
          expect(data.canProvisionAutomatically, isFalse);
          expect(data.canUseCompatMode, isFalse);
          expect(
            (await repository.provisionNtut8021x()).status,
            Ntut8021xProvisioningStatus.unsupportedPlatform,
          );
          expect(
            (await repository.saveNtut8021xToSystem()).status,
            Ntut8021xProvisioningStatus.unsupportedPlatform,
          );
          expect(platform.provisionCallCount, 0);
          expect(platform.compatCallCount, 0);
          final state = await stateStore.read();
          expect(
            state.lastProvisioningMode,
            Ntut8021xStoredProvisioningMode.none,
          );
          expect(
            state.pendingCompatPromptReason,
            Ntut8021xStoredPendingPromptReason.credentialChanged,
          );
          expect(state.pendingImmediatePrompt, isTrue);
        },
      );
    }
    for (final (mode, saveToSystem) in [
      (Ntut8021xStoredProvisioningMode.suggestion, false),
      (Ntut8021xStoredProvisioningMode.compat, true),
      (Ntut8021xStoredProvisioningMode.direct, false),
      (Ntut8021xStoredProvisioningMode.direct, true),
    ]) {
      test(
        'removal waits for earlier manual $mode provisioning (save: $saveToSystem)',
        () async {
          final authRepository = _FakeAuthRepository(
            localUser: _testUser,
            credentials: (username: '111360109', password: 'portal-password'),
          );
          addTearDown(authRepository.close);
          final prefs = SharedPreferencesAsync();
          final stateStore = Ntut8021xStateStore(prefs);
          final platform = _BlockingCampusWifiPlatform(isIos: mode == .direct);
          final repository = _buildRepository(
            authRepository: authRepository,
            platform: platform,
            stateStore: stateStore,
            provisioner: mode == .direct
                ? IosCampusWifiProvisioner(
                    platform: platform,
                    stateStore: stateStore,
                  )
                : AndroidCampusWifiProvisioner(
                    platform: platform,
                    stateStore: stateStore,
                  ),
          );
          final provisioning = saveToSystem
              ? repository.saveNtut8021xToSystem()
              : repository.provisionNtut8021x();
          await platform.started.future;
          final removal = repository.removeNtut8021x();
          await Future<void>.delayed(Duration.zero);
          platform.canFinish.complete();
          await provisioning;
          final removalStatus = await removal;

          expect(
            await prefs.getBool(ntut8021xAutoReprovisionPreferenceKey),
            isFalse,
          );
          final state = await stateStore.read();
          expect(
            state.lastProvisioningMode,
            Ntut8021xStoredProvisioningMode.none,
          );
          expect(state.pendingCompatPromptReason, isNull);
          expect(state.pendingImmediatePrompt, isFalse);
          expect(platform.removedDuringProvisioning, isFalse);
          expect(removalStatus, switch (mode) {
            .compat => Ntut8021xRemovalStatus.manualRemovalRequired,
            .direct => Ntut8021xRemovalStatus.removalRequested,
            _ => Ntut8021xRemovalStatus.removed,
          });
        },
      );
    }

    for (final blockEnable in [false, true]) {
      test(
        'removal waits for manual ${blockEnable ? 'enable' : 'state'} persistence',
        () async {
          final storage = _InMemorySharedPreferencesAsyncPlatform();
          SharedPreferencesAsyncPlatform.instance = storage;
          final writeStarted = Completer<void>();
          final allowWrite = Completer<void>();
          storage.beforeWrite = (key, value) async {
            final shouldBlock = blockEnable
                ? key == ntut8021xAutoReprovisionPreferenceKey && value == true
                : value == Ntut8021xStoredProvisioningMode.suggestion.name;
            if (shouldBlock) {
              writeStarted.complete();
              await allowWrite.future;
            }
          };
          final authRepository = _FakeAuthRepository(
            localUser: _testUser,
            credentials: (username: '111360109', password: 'portal-password'),
          );
          addTearDown(authRepository.close);
          final prefs = SharedPreferencesAsync();
          final stateStore = Ntut8021xStateStore(prefs);
          final platform = _FakeCampusWifiPlatform();
          final repository = _buildRepository(
            authRepository: authRepository,
            platform: platform,
            stateStore: stateStore,
          );

          final provisioning = repository.provisionNtut8021x();
          await writeStarted.future;
          final removal = repository.removeNtut8021x();
          await Future<void>.delayed(Duration.zero);
          expect(platform.removalCallCount, 0);
          allowWrite.complete();
          await provisioning;

          expect(await removal, Ntut8021xRemovalStatus.removed);
          expect(platform.removalCallCount, 1);
          expect(
            await prefs.getBool(ntut8021xAutoReprovisionPreferenceKey),
            isFalse,
          );
          final state = await stateStore.read();
          expect(
            state.lastProvisioningMode,
            Ntut8021xStoredProvisioningMode.none,
          );
          expect(state.pendingCompatPromptReason, isNull);
          expect(state.pendingImmediatePrompt, isFalse);
        },
      );
    }

    test('a failed manual setup cannot block later removal', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);
      final prefs = SharedPreferencesAsync();
      final stateStore = Ntut8021xStateStore(prefs);
      final platform = _BlockingCampusWifiPlatform();
      final repository = _buildRepository(
        authRepository: authRepository,
        platform: platform,
        stateStore: stateStore,
      );
      final provisioning = repository.provisionNtut8021x();
      await platform.started.future;
      final error = expectLater(provisioning, throwsStateError);
      final removal = repository.removeNtut8021x();
      platform.canFinish.completeError(StateError('Native setup failed'));
      await error;

      expect(await removal, Ntut8021xRemovalStatus.removed);
      expect(
        await prefs.getBool(ntut8021xAutoReprovisionPreferenceKey),
        isFalse,
      );
      expect(
        (await stateStore.read()).lastProvisioningMode,
        Ntut8021xStoredProvisioningMode.none,
      );
    });

    for (final (mode, wireStatus, expectedStatus, capabilities) in [
      (
        Ntut8021xStoredProvisioningMode.suggestion,
        'removed',
        Ntut8021xRemovalStatus.removed,
        _FakeCampusWifiPlatform().capabilities,
      ),
      (
        Ntut8021xStoredProvisioningMode.compat,
        'removed',
        Ntut8021xRemovalStatus.manualRemovalRequired,
        _FakeCampusWifiPlatform().capabilities,
      ),
      (
        Ntut8021xStoredProvisioningMode.direct,
        'removalRequested',
        Ntut8021xRemovalStatus.removalRequested,
        _iosCapabilities,
      ),
    ]) {
      test('$mode removal clears refresh state without credentials', () async {
        final authRepository = _FakeAuthRepository();
        addTearDown(authRepository.close);
        final prefs = SharedPreferencesAsync();
        final stateStore = Ntut8021xStateStore(prefs);
        await prefs.setBool(ntut8021xAutoReprovisionPreferenceKey, true);
        await stateStore.markProvisioned(mode: mode);
        await stateStore.setPendingCompatPrompt(
          reason: .credentialChanged,
          immediate: true,
        );
        final platform = _FakeCampusWifiPlatform(
          capabilities: capabilities,
          removalStatus: wireStatus,
        );
        final repository = _buildRepository(
          authRepository: authRepository,
          platform: platform,
          stateStore: stateStore,
          provisioner: mode == .direct
              ? IosCampusWifiProvisioner(
                  platform: platform,
                  stateStore: stateStore,
                )
              : AndroidCampusWifiProvisioner(
                  platform: platform,
                  stateStore: stateStore,
                ),
        );

        expect(await repository.removeNtut8021x(), expectedStatus);
        expect(
          await prefs.getBool(ntut8021xAutoReprovisionPreferenceKey),
          isFalse,
        );
        final state = await stateStore.read();
        expect(
          state.lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.none,
        );
        expect(state.pendingCompatPromptReason, isNull);
        expect(state.pendingImmediatePrompt, isFalse);
        expect(await repository.consumePendingImmediatePrompt(), isNull);
      });
    }

    test('failed removal preserves configuration state for retry', () async {
      final authRepository = _FakeAuthRepository();
      addTearDown(authRepository.close);
      final prefs = SharedPreferencesAsync();
      final stateStore = Ntut8021xStateStore(prefs);
      await stateStore.markProvisioned(mode: .suggestion);
      await prefs.setBool(ntut8021xAutoReprovisionPreferenceKey, true);
      final repository = _buildRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(removalStatus: 'failed'),
        stateStore: stateStore,
      );

      expect(await repository.removeNtut8021x(), Ntut8021xRemovalStatus.failed);
      expect(
        (await stateStore.read()).lastProvisioningMode,
        Ntut8021xStoredProvisioningMode.suggestion,
      );
      expect(
        await prefs.getBool(ntut8021xAutoReprovisionPreferenceKey),
        isFalse,
      );
    });
  });
}

const _iosCapabilities = (
  isSupported: true,
  androidSdkInt: null,
  canOpenWifiSettings: false,
  canOpenWifiPanel: false,
  canProvisionNtut8021xSuggestion: false,
  canProvisionNtut8021xCompat: false,
  canProvisionNtut8021x: true,
  suggestionPermissionState: 'unknown',
);

Ntut8021xProvisioningDto _iosResult(String status) => (
  status: status,
  androidSdkInt: null,
  usedHiddenCaPath: false,
  wifiEnabled: null,
  networkSuggestionStatus: null,
  approvalStatus: null,
  suggestionPermissionState: 'unknown',
  compatResultCode: null,
  compatNetworkResultCodes: const <int>[],
  message: null,
);

CampusWifiRepository _buildRepository({
  required _FakeAuthRepository authRepository,
  required _FakeCampusWifiPlatform platform,
  Ntut8021xStateStore? stateStore,
  CampusWifiProvisioner? provisioner,
}) {
  final prefs = SharedPreferencesAsync();
  final resolvedStateStore = stateStore ?? Ntut8021xStateStore(prefs);
  final resolvedProvisioner =
      provisioner ??
      AndroidCampusWifiProvisioner(
        platform: platform,
        stateStore: resolvedStateStore,
      );
  return CampusWifiRepository(
    authRepository: authRepository,
    platform: platform,
    provisioner: resolvedProvisioner,
    autoReprovision: Ntut8021xAutoReprovision(
      prefs: prefs,
      provisioner: resolvedProvisioner,
      stateStore: resolvedStateStore,
    ),
    stateStore: resolvedStateStore,
  );
}

const _testUser = User(
  id: 1,
  studentId: '111360109',
  nameZh: '王大同',
  avatarFilename: '',
  email: 't111360109@ntut.edu.tw',
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository._(this._database, {this.localUser, this.credentials})
    : super(
        portalService: MockPortalService(),
        studentQueryService: MockStudentQueryService(),
        database: _database,
        secureStorage: const FlutterSecureStorage(),
        isDemo: false,
        clearCourseWidget: _noopAsync,
        onSessionCreated: _noop,
        onSessionDestroyed: _noopDestroyed,
      );

  factory _FakeAuthRepository({
    User? localUser,
    ({String username, String password})? credentials,
  }) {
    final database = AppDatabase(NativeDatabase.memory());
    return _FakeAuthRepository._(
      database,
      localUser: localUser,
      credentials: credentials,
    );
  }

  final AppDatabase _database;
  final User? localUser;
  final ({String username, String password})? credentials;

  Future<void> close() => _database.close();

  @override
  Future<User?> getLocalUser() async => localUser;

  @override
  Future<({String username, String password})?> getStoredCredentials() async {
    return credentials;
  }
}

class _FakeCampusWifiPlatform implements CampusWifiPlatform {
  _FakeCampusWifiPlatform({
    this.removalStatus = 'removed',
    this.capabilities = const (
      isSupported: true,
      androidSdkInt: 34,
      canOpenWifiSettings: true,
      canOpenWifiPanel: true,
      canProvisionNtut8021xSuggestion: true,
      canProvisionNtut8021xCompat: true,
      canProvisionNtut8021x: true,
      suggestionPermissionState: 'allowed',
    ),
    this.provisioningResult = const (
      status: 'success',
      androidSdkInt: 34,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      compatResultCode: null,
      compatNetworkResultCodes: <int>[],
      suggestionPermissionState: null,
      message: null,
    ),
    this.compatResult = const (
      status: 'compatSuccess',
      androidSdkInt: 34,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      compatResultCode: 0,
      compatNetworkResultCodes: <int>[0],
      suggestionPermissionState: null,
      message: null,
    ),
  });

  final CampusWifiCapabilitiesDto capabilities;

  final Ntut8021xProvisioningDto provisioningResult;
  final Ntut8021xProvisioningDto compatResult;
  final String removalStatus;

  int provisionCallCount = 0;
  int compatCallCount = 0;
  int removalCallCount = 0;

  @override
  Future<String> removeNtut8021x() async {
    removalCallCount++;
    return removalStatus;
  }

  @override
  Future<CampusWifiCapabilitiesDto> getCapabilities() async => capabilities;

  @override
  Future<bool> openWifiPanel() async => capabilities.canOpenWifiPanel;

  @override
  Future<bool> openWifiSettings() async => capabilities.canOpenWifiSettings;

  @override
  Future<bool> openWifiPermissionSettings() async => true;

  @override
  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    provisionCallCount++;
    return provisioningResult;
  }

  @override
  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  }) async {
    compatCallCount++;
    return compatResult;
  }
}

class _BlockingCampusWifiPlatform extends _FakeCampusWifiPlatform {
  _BlockingCampusWifiPlatform({this.isIos = false})
    : super(
        capabilities: isIos
            ? _iosCapabilities
            : _FakeCampusWifiPlatform().capabilities,
        removalStatus: isIos ? 'removalRequested' : 'removed',
      );

  final bool isIos;
  final started = Completer<void>();
  final canFinish = Completer<void>();
  bool removedDuringProvisioning = false;

  @override
  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    started.complete();
    await canFinish.future;
    return isIos ? _iosResult('configured') : provisioningResult;
  }

  @override
  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  }) async {
    started.complete();
    await canFinish.future;
    return isIos ? _iosResult('configured') : compatResult;
  }

  @override
  Future<String> removeNtut8021x() async {
    removedDuringProvisioning = !canFinish.isCompleted;
    return super.removeNtut8021x();
  }
}

void _noop() {}

Future<void> _noopAsync() async {}

void _noopDestroyed([_]) {}

final class _InMemorySharedPreferencesAsyncPlatform
    extends SharedPreferencesAsyncPlatform {
  final _store = <String, Object>{};
  Future<void> Function(String key, Object value)? beforeWrite;

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) {
      _store.clear();
      return;
    }

    _store.removeWhere((key, _) => allowList.contains(key));
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async {
    return _store[key] as bool?;
  }

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _store[key] as double?;
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async {
    return _store[key] as int?;
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) return Map<String, Object>.from(_store);
    return Map<String, Object>.fromEntries(
      _store.entries.where((entry) => allowList.contains(entry.key)),
    );
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) return _store.keys.toSet();
    return _store.keys.where(allowList.contains).toSet();
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _store[key] as String?;
  }

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _store[key] as List<String>?;
  }

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async {
    await beforeWrite?.call(key, value);
    _store[key] = value;
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) async {
    await beforeWrite?.call(key, value);
    _store[key] = value;
  }

  @override
  Future<void> setInt(
    String key,
    int value,
    SharedPreferencesOptions options,
  ) async {
    await beforeWrite?.call(key, value);
    _store[key] = value;
  }

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    await beforeWrite?.call(key, value);
    _store[key] = value;
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    await beforeWrite?.call(key, value);
    _store[key] = value;
  }
}
