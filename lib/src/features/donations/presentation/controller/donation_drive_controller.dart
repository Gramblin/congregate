import 'package:congregate/src/features/donations/data/donation_drives_repository.dart';
import 'package:congregate/src/features/donations/domain/donation_drive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'donation_drive_controller.g.dart';

@riverpod
class DonationDriveNotifier extends _$DonationDriveNotifier {
  @override
  FutureOr<void> build() => null;

  Future<DonationDrive?> create({
    required String groupId,
    required String title,
    String? description,
    String? externalLink,
    double? goalAmount,
    String currency = 'USD',
  }) async {
    final repo = ref.read(donationDrivesRepositoryProvider);
    state = const AsyncLoading();
    DonationDrive? result;
    state = await AsyncValue.guard(() async {
      result = await repo.create(
        groupId: groupId,
        title: title,
        description: description,
        externalLink: externalLink,
        goalAmount: goalAmount,
        currency: currency,
      );
      ref.invalidate(donationDrivesProvider(groupId));
    });
    return result;
  }

  Future<void> deactivate(String driveId, String groupId) async {
    final repo = ref.read(donationDrivesRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.deactivate(driveId);
      ref.invalidate(donationDrivesProvider(groupId));
    });
  }
}
