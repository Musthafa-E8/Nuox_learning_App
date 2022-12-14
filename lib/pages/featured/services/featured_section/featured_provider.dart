import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:nuox_project/pages/account/sections/whishlist/whishlist_model.dart';
import 'package:nuox_project/pages/featured/sections/notifications_section/notification_model.dart';
import 'package:nuox_project/pages/featured/services/featured_section/sorted_course_model.dart';
import 'package:nuox_project/pages/featured/widgets/no_course_found_page.dart';
import 'package:nuox_project/pages/featured/widgets/see_all_page_featured.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'featured_model.dart';

class FeaturedProvider with ChangeNotifier {
  final RefreshController refreshController =
      RefreshController(initialRefresh: true);
  String hasNext = "true";
  int currentPage = 1;
  ValueNotifier<bool> toggleNotifier = ValueNotifier(true);
  bool? isWhishlistEmpty;
  WhishlistModel? whishlist;
  NotificationModel? notificationList;
  bool? isCourseNotFound;
  SortedCourseModel? sortedCourses;
  List<Autogenerated?> auto = [];
  List<Autogenerated?> autos = [];
  bool isLoading = false;
  Future<bool> samples({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
    } else {
      if (hasNext == "false") {
        refreshController.loadNoData();
        return false;
      }
    }
    isLoading = true;
    SharedPreferences shared = await SharedPreferences.getInstance();
    Response response;
    String? token = shared.getString("access_token");
    if (token == null) {
      response = await get(
        Uri.parse(
            "http://learningapp.e8demo.com/api/featured-course/?limit=2&page=$currentPage"),
      );
    } else {
      response = await get(
        Uri.parse(
            "http://learningapp.e8demo.com/api/featured-course/?auth_token=$token&limit=5&page=$currentPage"),
      );
    }
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      hasNext = data['has_next'].toString();
      notifyListeners();

      if (isRefresh) {
        autos = (data['data'] as List)
            .map((e) => Autogenerated.fromJson(
                  e,
                ))
            .toList();
      } else {
        autos.addAll((data['data'] as List)
            .map((e) => Autogenerated.fromJson(e))
            .toList());
      }
      isLoading = false;
      currentPage++;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<void> sample() async {
    try {
      isLoading = true;
      SharedPreferences shared = await SharedPreferences.getInstance();
      Response response;
      String? token = shared.getString("access_token");
      if (token == null) {
        response = await get(
          Uri.parse("http://learningapp.e8demo.com/api/featured-course/"),
        );
      } else {
        response = await get(
          Uri.parse(
              "http://learningapp.e8demo.com/api/featured-course/?auth_token=$token"),
        );
      }
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        auto = (data['data'] as List)
            .map((e) => Autogenerated.fromJson(
                  e,
                ))
            .toList();
        isLoading = false;
      }

      notifyListeners();
    } catch (e) {
      isLoading = false;
      print(e.toString());
    }
  }

  Future<void> getSortedCourses(
      {String? catagoryID,
      required String minPrice,
      required String maxPrice,
      required context}) async {
    try {
      Response response = await get(Uri.parse(catagoryID == null
          ? "http://learningapp.e8demo.com/api/course_filter/?min_price=$minPrice&max_price=$maxPrice&cate_id="
          : "http://learningapp.e8demo.com/api/course_filter/?min_price=$minPrice&max_price=$maxPrice&cate_id=$catagoryID"));

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        sortedCourses = SortedCourseModel.fromJson(data);
        print(sortedCourses!.data!.first.isWishlist);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SeeAllPageFeatured()),
        );
      } else {
        isCourseNotFound = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NoCourseFoundPage()),
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void getNotifications() async {
    try {
      SharedPreferences shared = await SharedPreferences.getInstance();
      var token = shared.getString("access_token");
      String auth = "Bearer $token";
      print(auth);
      var api = "http://learningapp.e8demo.com/api/notification/";
      Response response =
          await get(Uri.parse(api), headers: {"Authorization": auth});
      Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        notificationList = NotificationModel.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void disableNotificaton({required String disabled, required context}) async {
    try {
      SharedPreferences shared = await SharedPreferences.getInstance();
      var token = shared.getString("access_token");
      String auth = "Bearer $token";
      var api = "http://learningapp.e8demo.com/api/notification/";
      Response response = await post(Uri.parse(api),
          headers: {"Authorization": auth}, body: {"is_active": disabled});
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["status"] == "true") {
          toggleNotifier.value = true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              duration: const Duration(milliseconds: 600),
              backgroundColor: Colors.green,
              content: Text(
                data["data"],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              )));
        } else {
          toggleNotifier.value = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              duration: const Duration(milliseconds: 600),
              backgroundColor: Colors.red,
              content: Text(
                data["data"],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              )));
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void addToWhishlist(
      {required id, required variant, required context, required price}) async {
    try {
      SharedPreferences shared = await SharedPreferences.getInstance();
      var token = shared.getString("access_token");
      String auth = "Bearer $token";
      var api = "http://learningapp.e8demo.com/api/wishlist/";
      Response response = await post(Uri.parse(api), headers: {
        "Authorization": auth
      }, body: {
        "course": id.toString(),
        "variant": variant.toString(),
        "price": price.toString()
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            duration: Duration(milliseconds: 600),
            backgroundColor: Colors.green,
            content: Text(
              "Course added to the whishlist",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )));
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> getWhishlist() async {
    isWhishlistEmpty = false;
    try {
      SharedPreferences shared = await SharedPreferences.getInstance();
      var token = shared.getString("access_token");
      String auth = "Bearer $token";
      var api = "http://learningapp.e8demo.com/api/wishlist/";
      Response response = await get(
        Uri.parse(api),
        headers: {"Authorization": auth},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        whishlist = WhishlistModel.fromJson(data);
        notifyListeners();
      } else {
        isWhishlistEmpty = true;
        notifyListeners();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteFromWhishlist(
      {required String id, required context, required variant}) async {
    try {
      SharedPreferences shared = await SharedPreferences.getInstance();
      var token = shared.getString("access_token");
      String auth = "Bearer $token";
      var api = "http://learningapp.e8demo.com/api/wishlist/";
      Response response = await put(Uri.parse(api),
          headers: {"Authorization": auth},
          body: {"course": id.toString(), "variant": variant.toString()});
      log(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            duration: Duration(milliseconds: 600),
            backgroundColor: Colors.white,
            content: Text(
              "Course removed from wishlist",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            )));
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
