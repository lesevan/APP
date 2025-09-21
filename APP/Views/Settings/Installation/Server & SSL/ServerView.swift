
import SwiftUI

class NBFetchService {
    func fetch<T: Codable>(from urlString: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension ServerView {
	struct ServerPackModel: Codable {
		var cert: String
		var ca: String
		var key: String
		var info: ServerPackInfo
		
		private enum CodingKeys: String, CodingKey {
			case cert, ca, key1, key2, info
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			cert = try container.decode(String.self, forKey: .cert)
			ca = try container.decode(String.self, forKey: .ca)
			let key1 = try container.decode(String.self, forKey: .key1)
			let key2 = try container.decode(String.self, forKey: .key2)
			key = key1 + key2
			info = try container.decode(ServerPackInfo.self, forKey: .info)
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(cert, forKey: .cert)
			try container.encode(ca, forKey: .ca)
			// Split key back into key1 and key2 (assuming equal split)
			let keyLength = key.count
			let halfLength = keyLength / 2
			let key1 = String(key.prefix(halfLength))
			let key2 = String(key.suffix(keyLength - halfLength))
			try container.encode(key1, forKey: .key1)
			try container.encode(key2, forKey: .key2)
			try container.encode(info, forKey: .info)
		}
		
		struct ServerPackInfo: Codable {
			var issuer: Domains
			var domains: Domains
		}
		
		struct Domains: Codable {
			var commonName: String
			
			private enum CodingKeys: String, CodingKey {
				case commonName = "commonName"
			}
		}
	}
}

struct ServerView: View {
	@AppStorage("Feather.ipFix") private var _ipFix: Bool = true
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 1
	private let _serverMethods: [String] = ["完全本地", "半本地"]
	
	private let _dataService = NBFetchService()
	private let _serverPackUrl = "https://backloop.dev/pack.json"
	
	var body: some View {
		Group {
			Section {
				Picker("服务器类型", systemImage: "server.rack", selection: $_serverMethod) {
					ForEach(_serverMethods.indices, id: \.description) { index in
						Text(_serverMethods[index]).tag(index)
					}
				}
				Toggle("仅使用本地地址", systemImage: "lifepreserver", isOn: $_ipFix)
					.disabled(_serverMethod != 1)
			} footer: {
				Text("半本地模式（推荐）：使用本地网络地址，更稳定可靠。\n完全本地模式：需要有效的SSL证书。")
			}
			
			Section {
				Button("刷新安装方法的SSL证书", systemImage: "arrow.down.doc") {
					FR.downloadSSLCertificates(from: _serverPackUrl) { success in
						DispatchQueue.main.async {
							if success {
								UIAlertController.showAlertWithOk(
									title: "SSL证书",
									message: "SSL证书刷新成功！"
								)
							} else {
								UIAlertController.showAlertWithOk(
									title: "SSL证书",
									message: "下载失败，请检查网络连接后重试。"
								)
							}
						}
					}
				}
			} footer: {
				Text("更新SSL证书以支持HTTPS安装。如果下载失败，请检查网络连接。")
			}
		}
	}
}
