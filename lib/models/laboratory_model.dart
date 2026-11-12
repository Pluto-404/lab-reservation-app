import 'package:cloud_firestore/cloud_firestore.dart';

class LaboratoryModel {
  final String labId;                                        
  final String name;                                         
  final String building;                                     
  final int capacity;                                        
  final List<String> facilities;                             
  final String operationalHours;                             
  final bool isActive;                                       
  final String? imageUrl;

  LaboratoryModel({                                          
    required this.labId,                                     
    required this.name,                                      
    required this.building,                                  
    required this.capacity,                                  
    required this.facilities,                                
    required this.operationalHours,                          
    this.isActive = true,                                    
    this.imageUrl,                                           
  });
  
  Map<String, dynamic> toMap() {                             
    return {                                                 
      'lab_id': labId,                                       
      'name': name,                                          
      'building': building,                                  
      'capacity': capacity,                                  
      'facilities': facilities,                              
      'operational_hours': operationalHours,                
      'is_active': isActive,                                 
      'image_url': imageUrl,                                 
    };                                                       
  }

  factory LaboratoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LaboratoryModel(
      labId: doc.id,
      name: data['name'] ?? '',
      building: data['building'] ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      facilities: List<String>.from(data['facilities'] ?? []),
      operationalHours: data['operational_hours'] ?? '',
      isActive: data['is_active'] ?? true,
      imageUrl: data['image_url'],
    );
  }

}