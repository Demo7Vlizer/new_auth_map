import 'package:auth_map/controllers/upload_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/buttons/custom_button.dart';

class UploadDetailsScreen extends StatelessWidget {
  final _controller = Get.put(UploadDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              return Center(
                child: GestureDetector(
                  onTap: _controller.pickImage,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade200,
                      image: _controller.selectedImage.value != null
                          ? DecorationImage(
                              image:
                                  FileImage(_controller.selectedImage.value!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _controller.selectedImage.value == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            // TextField(
            //   controller: _controller.nameController,
            //   decoration: const InputDecoration(
            //     labelText: 'Name',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // const SizedBox(height: 20),
            // TextField(
            //   controller: _controller.emailController,
            //   decoration: const InputDecoration(
            //     labelText: 'Email',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            const SizedBox(height: 20),
            Obx(() => CustomButton(
                  text: 'Upload Details',
                  onPressed: _controller.isLoading.value
                      ? null
                      : _controller.uploadDetails,
                  isLoading: _controller.isLoading.value,
                )),
          ],
        ),
      ),
    );
  }
}
