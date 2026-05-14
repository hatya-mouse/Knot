//
//  A2UIComponent.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

struct A2UIComponent: Codable, Identifiable, Hashable {
    let id: String
    let component: String
    let label: String?
    let text: ValueOrBinding?
    let value: ValueOrBinding?
    let variant: String?
    let min: Double?
    let max: Double?
    let children: [String]?
    let child: String?
}
