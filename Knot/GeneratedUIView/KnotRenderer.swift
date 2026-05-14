//
//  KnotRenderer.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import SwiftUI

struct KnotRenderer: View {
    let components: [String: A2UIComponent]
    let thread: KnotThread
    let rootID: String

    var body: some View {
        renderComponent(id: rootID)
    }

    @ViewBuilder
    private func renderComponent(id: String) -> some View {
        if let comp = components[id] {
            AnyView(
                Group {
                    switch comp.component {
                    case "Row":
                        HStack {
                            childViews(ids: comp.children ?? [])
                        }
                    case "Column":
                        VStack(alignment: .leading, spacing: 8) {
                            childViews(ids: comp.children ?? [])
                        }
                    case "List":
                        List {
                            childViews(ids: comp.children ?? [], divider: true)
                        }
                    case "Divider":
                        Divider()
                    case "Text":
                        Text(self.resolveValue(comp.text, default: "" as String))
                    case "Button":
                        Button(action: {}) {
                            if let child = comp.child {
                                renderComponent(id: child)
                            }
                        }
                    case "TextField":
                        TextField(comp.label ?? "", text: self.resolveBinding(comp.value, default: ""))
                    case "CheckBox":
                        Toggle(comp.label ?? "", isOn: self.resolveBinding(comp.value, default: false))
                            .toggleStyle(.checkbox)
                    case "Slider":
                        VStack(alignment: .leading) {
                            if let label = comp.label { Text(label) }
                            Slider(value: self.resolveBinding(comp.value, default: 0), in: (comp.min ?? 0)...(comp.max ?? 100))
                        }
                    case "Card":
                        VStack(alignment: .leading, spacing: 12) {
                            childViews(ids: comp.children ?? [])
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    default:
                        Text("Unknown: \(comp.component)")
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func childViews(ids: [String], divider: Bool = false) -> some View {
        ForEach(ids, id: \.self) { childID in
            KnotRenderer(components: components, thread: thread, rootID: childID)
            if divider {
                Divider().padding(.vertical, 4)
            }
        }
    }

    private func resolveValue<T>(_ value: ValueOrBinding?, default defaultValue: T) -> T {
        switch value {
        case nil:
            return defaultValue
        case .literal(let value):
            return value.tryInto() ?? defaultValue
        case .binding(let path):
            return thread.get(for: path, defaultValue: defaultValue)
        }
    }

    private func resolveBinding<T>(_ value: ValueOrBinding?, default defaultValue: T) -> Binding<T> {
        switch value {
        case nil:
            return .constant(defaultValue)
        case .literal(let value):
            return .constant(value.tryInto() ?? defaultValue)
        case .binding(let path):
            return thread.binding(for: path, defaultValue: defaultValue)
        }
    }
}

struct CardStyle: ViewModifier {
    let isCard: Bool
    func body(content: Content) -> some View {
        if isCard {
            content.padding(8).background(RoundedRectangle(cornerRadius: 8).stroke(.secondary))
        } else {
            content
        }
    }
}
