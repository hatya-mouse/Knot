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
    let onComponentHover: (String?) -> Void
    let communicator: MCPAICommunicator

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
                        Text(
                            resolveValue(comp.text, default: "" as String)
                        )
                        .variant(comp.variant)
                    case "Button":
                        Button {
                            Task {
                                await communicator.triggerMCPTool(comp.id)
                            }
                        } label: {
                            if let child = comp.child {
                                renderComponent(id: child)
                            }
                        }
                        .hoverTooltip(
                            closure: onComponentHover,
                            "Action: \(comp.id)"
                        )
                    case "TextField":
                        TextField(
                            comp.label ?? "",
                            text: self.resolveBinding(comp.value, default: "")
                        )
                        .hoverTooltip(
                            closure: onComponentHover,
                            "TextField: \(comp.id)"
                        )
                    case "CheckBox":
                        Toggle(
                            comp.label ?? "",
                            isOn: resolveBinding(
                                comp.value,
                                default: false
                            )
                        )
                        .toggleStyle(.checkbox)
                        .hoverTooltip(
                            closure: onComponentHover,
                            "CheckBox: \(comp.id)"
                        )
                    case "Slider":
                        VStack(alignment: .leading) {
                            if let label = comp.label { Text(label) }
                            Slider(
                                value: resolveBinding(
                                    comp.value,
                                    default: 0
                                ),
                                in: (comp.min ?? 0)...(comp.max ?? 100)
                            )
                        }
                        .hoverTooltip(
                            closure: onComponentHover,
                            "Slider: \(comp.id)"
                        )
                    case "Card":
                        VStack(alignment: .leading, spacing: 12) {
                            if let child = comp.child {
                                childViews(ids: [child])
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    Color(NSColor.windowBackgroundColor)
                                        .opacity(0.5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color(.separatorColor),
                                            lineWidth: 1
                                        )
                                )
                        )
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
            KnotRenderer(
                components: components,
                thread: thread,
                rootID: childID,
                onComponentHover: onComponentHover,
                communicator: communicator
            )
            if divider {
                Divider().padding(.vertical, 4)
            }
        }
    }

    private func resolveValue<T>(
        _ value: ValueOrBinding?,
        default defaultValue: T
    ) -> T {
        switch value {
        case nil:
            return defaultValue
        case .literal(let value):
            return value.tryInto() ?? defaultValue
        case .binding(let path):
            return thread.get(for: path, defaultValue: defaultValue)
        }
    }

    private func resolveBinding<T>(
        _ value: ValueOrBinding?,
        default defaultValue: T
    ) -> Binding<T> {
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
            content.padding(8).background(
                RoundedRectangle(cornerRadius: 8).stroke(.secondary)
            )
        } else {
            content
        }
    }
}

extension View {
    fileprivate func hoverTooltip(
        closure: @escaping (String?) -> Void,
        _ tooltip: String
    ) -> some View {
        onHover { isHovered in
            closure(isHovered ? tooltip : nil)
        }
    }
}

extension Text {
    fileprivate func variant(_ variant: String?) -> some View {
        switch variant {
        case "h1": self.font(.largeTitle)
        case "h2": self.font(.title)
        case "h3": self.font(.title2)
        case "h4": self.font(.title3)
        case "h5": self.bold()
        case "caption": self.font(.caption).foregroundStyle(.secondary)
        case "body": self
        default: self
        }
    }
}
