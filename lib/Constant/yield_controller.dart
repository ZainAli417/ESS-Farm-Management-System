// farm_controller.dart
import 'package:get/get.dart';

import 'farmer_provider.dart';

class FarmController extends GetxController {
  // Observable list of farms loaded from Firestore.
  var farms = <FarmPlot>[].obs;

  // The currently selected farm (if any)
  var selectedFarm = Rxn<FarmPlot>();

  @override
  void onInit() {
    super.onInit();
    loadFarms();
  }

  // Listen to the Firestore stream and update the list.
  void loadFarms() {
    FarmPlot.loadFarms().listen((farmList) {
      farms.assignAll(farmList);
    });
  }

  void selectFarm(FarmPlot farm) {
    selectedFarm.value = farm;
  }
}
