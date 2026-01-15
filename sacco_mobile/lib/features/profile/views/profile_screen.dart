import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/features/profile/views/document_upload_screen.dart';
import 'package:sacco_mobile/features/profile/views/document_viewer.dart';
import 'package:sacco_mobile/features/profile/views/edit_profile_screen.dart';
import 'package:sacco_mobile/features/profile/views/next_of_kin_form_screen.dart';
import 'package:sacco_mobile/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';
import 'package:sacco_mobile/shared/widgets/error_widget.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load profile data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadMemberProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<ProfileViewModel>(),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: viewModel.state == ProfileState.loading
                      ? null
                      : () => viewModel.refreshProfile(),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Personal'),
                  Tab(text: 'Membership'),
                  Tab(text: 'Next of Kin'),
                ],
              ),
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(ProfileViewModel viewModel) {
    switch (viewModel.state) {
      case ProfileState.loading:
        return const Center(
          child: LoadingIndicator(
            message: 'Loading profile...',
          ),
        );
      case ProfileState.success:
        if (viewModel.memberProfile == null) {
          return const AppErrorWidget(
            message: 'Profile data not found',
            icon: Icons.person_off,
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalInfoTab(viewModel),
            _buildMembershipTab(viewModel),
            _buildNextOfKinTab(viewModel),
          ],
        );
      case ProfileState.error:
        return AppErrorWidget(
          message: viewModel.errorMessage ?? 'Failed to load profile data',
          onRetry: () => viewModel.refreshProfile(),
        );
      case ProfileState.initial:
        return const Center(
          child: LoadingIndicator(message: 'Initializing...'),
        );
    }
  }

  Widget _buildPersonalInfoTab(ProfileViewModel viewModel) {
    final profile = viewModel.memberProfile!;
    final dateFormat = DateFormat('dd MMM, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture and basic info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profile.passportPhotoUrl != null
                      ? NetworkImage(profile.passportPhotoUrl!)
                      : null,
                  child: profile.passportPhotoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  '${profile.maritalStatusText} • ${profile.employmentStatusText}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      text: 'Edit Profile',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              profile: viewModel.memberProfile!,
                            ),
                          ),
                        );
                      },
                      buttonType: ButtonType.outline,
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      text: 'Upload Photo',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DocumentUploadScreen(
                              documentType: 'PHOTO',
                              documentTitle: 'Profile Photo',
                            ),
                          ),
                        );
                      },
                      buttonType: ButtonType.outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal information card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      'Date of Birth', dateFormat.format(profile.dateOfBirth)),
                  _buildInfoRow('National ID', profile.nationalId),
                  _buildInfoRow(
                      'Occupation', profile.occupation ?? 'Not specified'),
                  _buildInfoRow('Monthly Income',
                      'UGX ${NumberFormat.decimalPattern().format(profile.monthlyIncome)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact information card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Physical Address', profile.physicalAddress),
                  _buildInfoRow('Postal Address',
                      profile.postalAddress ?? 'Not specified'),
                  _buildInfoRow('City', profile.city),
                  _buildInfoRow('District', profile.district),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipTab(ProfileViewModel viewModel) {
    final profile = viewModel.memberProfile!;
    final dateFormat = DateFormat('dd MMM, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Membership status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Membership Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: profile.isActive
                              ? Colors.green[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          profile.membershipStatusText,
                          style: TextStyle(
                            color: profile.isActive
                                ? Colors.green[800]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Member Number', profile.memberNumber),
                  _buildInfoRow('Membership Number', profile.membershipNumber),
                  _buildInfoRow('Membership Type', profile.membershipTypeText),
                  _buildInfoRow('Registration Date',
                      dateFormat.format(profile.registrationDate)),
                  _buildInfoRow(
                    'Verification Status',
                    profile.isVerified ? 'Verified' : 'Not Verified',
                    valueColor: profile.isVerified
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Documents card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentItem(
                    'National ID',
                    profile.idDocumentUrl != null,
                    onUpload: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocumentUploadScreen(
                            documentType: 'ID',
                            documentTitle: 'National ID',
                          ),
                        ),
                      );
                    },
                    onView: profile.idDocumentUrl != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DocumentViewerScreen(
                                  documentUrl: profile.idDocumentUrl!,
                                  documentName: 'National ID',
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                  const Divider(),
                  _buildDocumentItem(
                    'Passport Photo',
                    profile.passportPhotoUrl != null,
                    onUpload: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocumentUploadScreen(
                            documentType: 'PHOTO',
                            documentTitle: 'Passport Photo',
                          ),
                        ),
                      );
                    },
                    onView: profile.passportPhotoUrl != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DocumentViewerScreen(
                                  documentUrl: profile.passportPhotoUrl!,
                                  documentName: 'Passport Photo',
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextOfKinTab(ProfileViewModel viewModel) {
    final nextOfKin = viewModel.nextOfKin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next of Kin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppButton(
                text: 'Add',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NextOfKinFormScreen(),
                    ),
                  );
                },
                iconData: Icons.add,
                buttonType: ButtonType.outline,
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Next of kin list
          if (nextOfKin.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'No next of kin added yet',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nextOfKin.length,
              itemBuilder: (context, index) {
                final kin = nextOfKin[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              kin['full_name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${kin['percentage_share']}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getRelationshipText(kin['relationship']),
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${kin['phone_number']}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        if (kin['email'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Email: ${kin['email']}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => NextOfKinFormScreen(
                                      nextOfKin: kin,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                _showDeleteConfirmation(
                                    context, viewModel, kin['id']);
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String name, bool isUploaded,
      {VoidCallback? onUpload, VoidCallback? onView}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isUploaded ? Icons.check_circle : Icons.file_upload,
                color: isUploaded ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isUploaded)
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              TextButton.icon(
                onPressed: onUpload,
                icon:
                    Icon(isUploaded ? Icons.upload_file : Icons.add, size: 18),
                label: Text(isUploaded ? 'Update' : 'Upload'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRelationshipText(String relationship) {
    switch (relationship) {
      case 'SPOUSE':
        return 'Spouse';
      case 'CHILD':
        return 'Child';
      case 'PARENT':
        return 'Parent';
      case 'SIBLING':
        return 'Sibling';
      case 'OTHER':
        return 'Other';
      default:
        return relationship;
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, ProfileViewModel viewModel, int nextOfKinId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Next of Kin'),
          content: const Text(
              'Are you sure you want to delete this next of kin? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await viewModel.deleteNextOfKin(nextOfKinId);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[700],
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
