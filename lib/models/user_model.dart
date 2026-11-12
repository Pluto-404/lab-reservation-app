import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String nim;
  final String className;
  final String cohort;
  final String role; // 'student' or 'admin'
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.nim,
    required this.className,
    required this.cohort,
    this.role = 'student', // Default role is 'student'
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {                             
    return {                                                 
      'uid': uid,                                            
      'email': email,                                        
      'name': name,                                          
      'nim': nim,                                            
      'class_name': className,                               
      'cohort': cohort,                                      
      'role': role,                                          
      'photo_url': photoUrl,                                 
      'created_at': Timestamp.fromDate(createdAt),           
    };                                                       
  } 

  factory UserModel.fromFirestore(DocumentSnapshot doc) {    
    final data = doc.data() as Map<String, dynamic>? ?? {};  
                                                              
    return UserModel(                                        
      uid: doc.id,                                           
      email: data['email'] ?? '',                            
      name: data['name'] ?? '',                              
      nim: data['nim'] ?? '',                                
      className: data['class_name'] ?? '',                   
      cohort: data['cohort'] ?? '',                          
      role: data['role'] ?? 'student',                       
      photoUrl: data['photo_url'],                           
      createdAt: (data['created_at'] as Timestamp?)?.toDate()
      ?? DateTime.now(),                                     
    );
  }
}