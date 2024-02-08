import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../root/root_controller.dart';
import 'api/model/FolderDto.dart';
import 'api/wishlist_api.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({Key? key}) : super(key: key);

  @override
  _WishlistState createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  // 이미지 선택 상태를 관리하기 위한 집합
  final Set<int> _selectedItems = {};

  List<FolderDto> folderList = [];
  WishlistApi wishlistApi = WishlistApi();
  int _itemCount = 0;
  bool _isEditing = false; // 편집 모드 상태를 관리하는 변수

  @override
  void initState() {
    super.initState();
    fetchWishlistFolders();
  }

  Future<void> fetchWishlistFolders() async {
    try {
      var folders = await wishlistApi.getWishlistFolder();
      setState(() {
        folderList = folders;
        // 모든 폴더의 아이템 수를 합산하여 _itemCount를 업데이트
        _itemCount =
            folderList.fold(0, (sum, folder) => sum + folder.items.length);
      });
    } catch (e) {
      print('폴더 목록 가져오기 실패: $e');
    }
  }

  Future<void> updateWishlistBought() async {
    try {
      await wishlistApi.sendSelectedItemsToServer(_selectedItems);
      setState(() {
        fetchWishlistFolders(); // UI를 갱신하기 위해 데이터를 다시 불러옵니다.
        _selectedItems.clear();
      });
    } catch (e) {
      print('위시리스트 제품 구매여부 변환 실패: $e');
    }
  }

  Future<void> deleteWishlistItem() async {
    try {
      await wishlistApi.deleteWishlistItems(_selectedItems);
      setState(() {
        fetchWishlistFolders(); // UI를 갱신하기 위해 데이터를 다시 불러옵니다.
        _selectedItems.clear();
      });
    } catch (e) {
      print('위시리스트 제품 구매여부 변환 실패: $e');
    }
  }

  Future<void> restoreWishlistItem() async {
    try {
      await wishlistApi.restoreWishlistItems(_selectedItems);
      setState(() {
        fetchWishlistFolders(); // UI를 갱신하기 위해 데이터를 다시 불러옵니다.
        _selectedItems.clear();
      });
    } catch (e) {
      print('위시리스트 제품 구매여부 변환 실패: $e');
    }
  }


  Widget _buildTabBar() {
    return TabBar(
      tabs: folderList.map((folder) => Tab(text: folder.folderName)).toList(),
    );
  }

  void _toggleEditing() async {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedItems.clear();
      }
    });
    // RootController의 isEditing 상태도 업데이트
    RootController.to.isEditing.value = _isEditing;

    // 편집 모드를 종료하면서 변경된 사항이 있다면 데이터를 새로고침
    if (!_isEditing) {
      // 변경사항을 서버에 반영하는 로직 (필요한 경우)
      if (_selectedItems.isNotEmpty) {
        await updateWishlistBought(); // 선택된 아이템을 서버에 업데이트
      }
      // 데이터를 새로고침
      await fetchWishlistFolders(); // 폴더 목록을 다시 가져옴
    }
  }

  Widget _buildGridItem(FolderDto folder, int index) {
    final int wishlistItemId = folder.items[index].wishlistItemId;
    final bool isBought = folder.items[index].bought == 1;
    // isSelected를 정의합니다. 여기서 _selectedItems는 선택된 아이템의 ID를 담고 있는 리스트입니다.
    final bool isSelected = _selectedItems.contains(wishlistItemId);
    return GestureDetector(
      onTap: () {
        if (_isEditing) {
          setState(() {
            if (isSelected) {
              _selectedItems.remove(wishlistItemId);
            } else {
              _selectedItems.add(wishlistItemId);
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.network(
            folder.items[index].imageUrl,
            width: 102.0,
            height: 120.0,
            fit: BoxFit.cover,
          ),
          // 구매 표시
          if (isBought) ...[
            Container(
              width: 102.0,
              height: 120.0,
              color: Colors.black.withOpacity(0.5),
            ),
            Transform.rotate(
              angle: -0.785398, // 45 degrees in radians
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'COMPLETE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          // 편집 모드에서의 선택 표시
          if (_isEditing)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 24.0,
                height: 24.0,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(isSelected ? 0 : 1),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(Icons.check_circle_rounded,
                    color: Colors.blue) // 이미 선택된 경우 체크 아이콘 표시
                    : Container(), // 선택되지 않은 경우 회색 동그라미 표시
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    print("folderList length: ${folderList.length}");
    return TabBarView(
      children: folderList.map((folder) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: folder.items.length,
          itemBuilder: (context, index) {
            return _buildGridItem(folder, index); // 각 이미지를 선택 가능한 아이템으로 구성
          },
        );
      }).toList(),
    );
  }

  Widget _wishlistWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          color: Color(0xff343F56),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 30,
                ),
                Text(
                  ' Wishlist',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        DefaultTabController(

          length: folderList.length,
          initialIndex: 0,
          child: Column(
            children: [
              _buildTabBar(), // TabBar
              _buildItemCountAndEditButton(), // Add this line
              Container(
                height: 900,
                child: _buildTabBarView(), // TabBarView
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildItemCountAndEditButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
              'Items (${folderList.fold(0, (previousValue, folder) => previousValue + folder.items.length)})'),
          Obx(() => TextButton(
            onPressed: _toggleEditing,
            child: Text(
                Get.find<RootController>().isEditing.isTrue
                    ? 'Done'
                    : 'Edit',
                style: TextStyle(color: Colors.blue)),
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )),
        ],
      ),
    );
  }


  Widget _buildEditingBottomBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.black,
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // 첫 번째 항목: 구매
          Column(
            mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기를 최소로 설정
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.check_circle_outline_outlined, color: Colors.white),
                onPressed: updateWishlistBought,
              ),
              Text('PURCHASE', style: TextStyle(color: Colors.white, fontSize: 4)),
            ],
          ),
          // 두 번째 항목: 복원
          Column(
            mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기를 최소로 설정
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.shopping_cart_sharp, color: Colors.white),
                onPressed: restoreWishlistItem,
              ),
              Text('RESTORE', style: TextStyle(color: Colors.white, fontSize: 4)),
            ],
          ),
          // 세 번째 항목: 삭제
          Column(
            mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기를 최소로 설정
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: deleteWishlistItem,
              ),
              Text('DELETE', style: TextStyle(color: Colors.white, fontSize: 4)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    // GetX 컨트롤러 인스턴스를 얻습니다.
    final RootController rootController = Get.find<RootController>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _wishlistWidget(context),
            Padding(
              padding: EdgeInsets.only(bottom: 80.0), // BottomAppBar에 공간을 제공
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: Obx(
            () => Visibility(
          visible: rootController.isEditing.isTrue,
          child: _buildEditingBottomBar(context),
          replacement: SizedBox.shrink(), // `null` 대신 사용될 위젯
        ),
      ), // Obx를 사용하여 BottomNavigationBar 추가
    );
  }
}
