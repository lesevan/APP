//  AccountView.swift
//
//  Created by pxx917144686 on 2025/08/20.
//
import SwiftUI

struct AccountView: View {
    @State var addSheet = false
    @State var animation = false
    @EnvironmentObject var appStore: AppStore
    
    var body: some View {
        NavigationView {
            VStack {
                if appStore.accounts.isEmpty {
                    // Empty State View with Modern Design
                    VStack(spacing: 30) {
                        Spacer()
                        VStack(spacing: 20) {
                            // Logo with Animation
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.blue)
                                .scaleEffect(animation ? 1.1 : 1)
                                .opacity(animation ? 1 : 0.7)
                                .animation(
                                    Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: animation
                                )
                            // Welcome Text
                            VStack(spacing: 12) {
                                Text("Apple ID")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("遇到问题,联系pxx917144686")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        // Add Account Button
                        Button(action: { addSheet.toggle() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                                Text("添加账户")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    // 显示账户列表
                    List {
                        ForEach(appStore.accounts) { account in
                            AccountDetailView(account: account)
                        }
                        .onDelete(perform: deleteAccount)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("Apple ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Apple ID")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !appStore.accounts.isEmpty {
                        Button(action: { addSheet.toggle() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $addSheet) {
                AddAccountView()
                    .environmentObject(AppStore.this)
            }
            .onAppear {
                animation = true
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func deleteAccount(offsets: IndexSet) {
        for index in offsets {
            let account = appStore.accounts[index]
            appStore.delete(id: account.id)
        }
    }
}
