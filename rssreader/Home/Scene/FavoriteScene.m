//
//  FavoriteScene.m
//  rssreader
//
//  Created by 朱潮 on 14-8-24.
//  Copyright (c) 2014年 zhuchao. All rights reserved.
//

#import "FavoriteScene.h"
#import "RssCell.h"
#import "RssDetailScene.h"
#import "FeedSceneModel.h"
#import "FavSceneModel.h"

@interface FavoriteScene ()<SWTableViewCellDelegate>
@property(nonatomic,retain)FavSceneModel *favSceneModel;
@property(nonatomic,retain)NSMutableArray *dataArray;
@end

@implementation FavoriteScene

- (void)viewDidLoad {
    [super viewDidLoad];
    _favSceneModel = [FavSceneModel sharedInstance];
    self.dataArray = [NSMutableArray array];
    
    @weakify(self);
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        @strongify(self);
        self.favSceneModel.pagination.page = @1;
    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
         @strongify(self);
        self.favSceneModel.pagination.page = [self.favSceneModel.pagination.page increase:@1];
    }];
    
    [RACObserve(self.favSceneModel, favArray)
    subscribeNext:^(NSArray* array) {
        [[GCDQueue mainQueue] queueBlock:^{
            @strongify(self);
            self.dataArray = [self.favSceneModel.pagination success:self.dataArray newArray:array];
            [self.tableView reloadData];
        }];
    }];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Rss *rss = [self.dataArray objectAtIndex:indexPath.row];
    CGFloat height = 45;
    if (rss.summary.isNotEmpty) {
        height +=50;
    }
    if(rss.imageUrl.isNotEmpty){
        height +=200;
    }
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (RssCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SettingTableIdentifier = @"RssCell";
    RssCell *cell = [[RssCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SettingTableIdentifier];
    cell.delegate = self;
    cell.rightUtilityButtons = [self rightButtons];
    Rss *rss = [self.dataArray objectAtIndex:indexPath.row];
    [cell reloadRss:rss];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    RssDetailScene* scene =  [self.storyboard instantiateViewControllerWithIdentifier:@"RssDetailScene"];
    scene.rss = [self.dataArray objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:scene animated:YES];
}


- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithString:@"#20F298"]
                                                title:@"取消收藏"];
    return rightUtilityButtons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (index == 0) { //删除
        Rss *rss = [self.dataArray objectAtIndex:indexPath.row];
                rss.isFav = 0;
                [rss saveFav];
        [self.dataArray removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}



@end
