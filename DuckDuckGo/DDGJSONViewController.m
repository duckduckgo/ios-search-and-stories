//
//  DDGJSONViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/13/12.
//
//

#import "DDGJSONViewController.h"

@interface DDGJSONViewController ()

@end

@implementation DDGJSONViewController

-(void)setJsonURL:(NSURL *)jsonURL {
    _jsonURL = jsonURL;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:_jsonURL];
        NSArray *newJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            json = newJSON;
            [self.tableView reloadData];
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return json.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[json objectAtIndex:section] objectForKey:@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[json objectAtIndex:section] objectForKey:@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *row = [[[json objectAtIndex:indexPath.section] objectForKey:@"rows"] objectAtIndex:indexPath.row];
    cell.textLabel.text = [row objectForKey:@"title"];
    cell.detailTextLabel.text = [row objectForKey:@"description"];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CGFloat height = CGRectIntegral([cell.detailTextLabel.text boundingRectWithSize:cell.detailTextLabel.frame.size
                                                                            options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                                         attributes:@{NSFontAttributeName: cell.detailTextLabel.font}
                                                                            context:nil]).size.height;
    return 44.0f + height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

@end
