//
//  TCLMainViewController.m
//  TestCatalog
//
//  Created by Могрин on 10/19/14.
//  Copyright (c) 2014 Могрин. All rights reserved.
//

#import "TCLMainViewController.h"
#import "TCLDirectory.h"

NSNumber *const ROOT_ID = 0;

@interface TCLMainViewController ()

@end


@implementation TCLMainViewController

@synthesize directories;
@synthesize runDirectory;
@synthesize runDirectoryId;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
    [self reloadTableView];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.runDirectoryId = ROOT_ID;
    
    UIBarButtonItem *editButton = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  target:self
                                  action:@selector(insertNewObject:)];
    
    self.navigationItem.rightBarButtonItem = addButton;
    
    NSArray *rightButtons = [[NSArray alloc] initWithObjects: addButton, editButton, nil];
    self.navigationItem.rightBarButtonItems = rightButtons;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                   target:self
                                   action:@selector(goBackDir:)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)insertNewObject:(id)sender
{
    [self getDialog];
}

-(void)getDialog
{
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"Создать директорию", nil)
                           message:NSLocalizedString(@"", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"Создать", nil)
                           otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *tmpTitle = [[alertView textFieldAtIndex:0] text]; 
    
    if( tmpTitle.length >= 1 ){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSManagedObject *newDir= [NSEntityDescription insertNewObjectForEntityForName:@"Directory"
                                                                   inManagedObjectContext:context];
        [newDir setValue:tmpTitle forKey:@"title"];
        [newDir setValue:[[NSNumber alloc] initWithInt:[NSDate timeIntervalSinceReferenceDate]] forKey:@"id"];
        [newDir setValue:self.runDirectoryId forKey:@"parentId"];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
        [self.directories insertObject:newDir atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}



#pragma mark - Table view data source

-(void)reloadTableView
{
    [self.directories removeAllObjects];
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Directory"];
    NSPredicate *predicateId = [NSPredicate predicateWithFormat:@"parentId == %d", [self.runDirectoryId integerValue]];
    [fetchRequest setPredicate:predicateId];
    self.directories = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    
    if([self.runDirectoryId integerValue] == [ROOT_ID integerValue]){
        self.navigationItem.title = @"Каталог";
        self.navigationItem.leftBarButtonItem.enabled = false;
    }
    else {
        NSPredicate *tmpPredicate = [NSPredicate predicateWithFormat:@"id == %d", [self.runDirectoryId integerValue]];
        [fetchRequest setPredicate:tmpPredicate];        
        self.runDirectory = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] objectAtIndex:0];
        self.runDirectoryId = [self.runDirectory valueForKey:@"id"];
        self.navigationItem.title = [self.runDirectory valueForKey:@"title"];
        self.navigationItem.leftBarButtonItem.enabled = true;
    }
    
    
    [self.tableView reloadData];
   
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.directories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSManagedObject *directory = [self.directories objectAtIndex:indexPath.row];
    [cell.textLabel setText:[directory valueForKey:@"title"]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSManagedObject *tmpDir = [self.directories objectAtIndex:indexPath.row];
        
        [context deleteObject: tmpDir];
        [self removeSubDirectories:[tmpDir valueForKey:@"id"]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Delete! %@ %@", error, [error localizedDescription]);
            return;
        }
        
        [self.directories removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } 
}

- (void) removeSubDirectories:(NSNumber*)idDir
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Directory"];
    NSPredicate *predicateId = [NSPredicate predicateWithFormat:@"parentId == %d", [idDir integerValue]];
    [fetchRequest setPredicate: predicateId];
    NSMutableArray *removeDir = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    for(NSManagedObject *n in removeDir)
    {
        [self removeSubDirectories:[n valueForKey:@"id"]];
        [context deleteObject:n];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.runDirectoryId = [[self.directories objectAtIndex:indexPath.row] valueForKey:@"id"];      
    [self reloadTableView];
}

- (void)goBackDir:(id)sender
{
    self.runDirectoryId = [self.runDirectory valueForKey:@"parentId"];
    [self reloadTableView];
}

@end





