import 'package:appwrite/appwrite.dart';

void main() async {
  print('Testing Appwrite connection...');
  
  try {
    // Initialize Appwrite client with your exact settings
    final client = Client()
      ..setEndpoint('https://nyc.cloud.appwrite.io/v1')
      ..setProject('68ac6493003072efa8c5');
    
    final account = Account(client);
    
    print('Creating anonymous session...');
    await account.createAnonymousSession();
    print('✅ Anonymous session created successfully!');
    
    // Test a simple database operation
    final databases = Databases(client);
    print('Testing database access...');
    
    final documents = await databases.listDocuments(
      databaseId: '68ac64ea0032f91f0fc7',
      collectionId: 'users',
      queries: [Query.limit(1)],
    );
    
    print('✅ Database access successful! Found ${documents.documents.length} documents');
    
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
