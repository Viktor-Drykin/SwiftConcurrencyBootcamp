//
//  SearchableBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 14.12.2024.
//

import SwiftUI
import Combine

struct Restaurant: Identifiable, Hashable {
    let id: String
    let title: String
    let cuisine: CuisineOption
}

enum CuisineOption: String {
    case american, italian, japanese
}

final class RestaurantManager {

    func getAllRestaurants() async throws -> [Restaurant] {
        [
            .init(id: "1", title: "Burger Rest", cuisine: .american),
            .init(id: "2", title: "Pasta Rest", cuisine: .italian),
            .init(id: "3", title: "Sushi Rest", cuisine: .japanese),
            .init(id: "4", title: "Katyusha", cuisine: .american),

        ]
    }

}

@MainActor
final class SearchableViewModel: ObservableObject {

    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    @Published var searchScope: SearchScopeOption = .all
    @Published private(set) var searchScopes: [SearchScopeOption] = []
    private var allRestaurants: [Restaurant] = []
    let manager = RestaurantManager()
    private var cancellables = Set<AnyCancellable>()

    enum SearchScopeOption: Hashable {
        case all
        case cuisine(option: CuisineOption)

        var title: String {
            switch self {
            case .all:
                return "All"
            case .cuisine(option: let option):
                return option.rawValue.capitalized
            }
        }
    }

    var showSearchSuggestions: Bool {
        searchText.count < 4
    }

    init() {
        addSubscribers()
    }

    private func addSubscribers() {
        $searchText
            .combineLatest($searchScope)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] searchedText, currentSearchScope in
                self?.filterRestaurants(searchText: searchedText, currentSearchScope: currentSearchScope)
            }
            .store(in: &cancellables)
    }

    private func filterRestaurants(searchText: String, currentSearchScope: SearchScopeOption) {
        guard !searchText.isEmpty else {
            filteredRestaurants = allRestaurants
            searchScope = .all
            return
        }

        let restaurantsInScope = {
            switch currentSearchScope {
            case .all:
                return allRestaurants
            case .cuisine(let option):
                return allRestaurants.filter { $0.cuisine == option }
            }
        }()

        filteredRestaurants = restaurantsInScope.filter { restaurant in
            let titleContainsSearch = restaurant.title.range(of: searchText, options: .caseInsensitive) != nil
            let cuisineContainsSearch = restaurant.cuisine.rawValue.range(of: searchText, options: .caseInsensitive) != nil
            return titleContainsSearch || cuisineContainsSearch
        }
    }

    func loadRestaurants() async {
        do {
            allRestaurants = try await manager.getAllRestaurants()
            let allCuisines = Set(allRestaurants.map { $0.cuisine })
            searchScopes = [.all] + allCuisines.map { SearchScopeOption.cuisine(option: $0) }
            filterRestaurants(searchText: searchText, currentSearchScope: searchScope)
        } catch {
            print(error)
        }
    }

    func getSearchSuggestions() -> [String] {
        guard showSearchSuggestions else { return [] }

        var suggestions: [String] = []
        let search = searchText.lowercased()
        if search.contains("pa") {
            suggestions.append("Pasta")
        }
        if search.contains("su") {
            suggestions.append("Sushi")
        }
        if search.contains("bu") {
            suggestions.append("Burger")
        }
        suggestions.append("Market")
        suggestions.append("Grocery")

        suggestions.append(CuisineOption.italian.rawValue.capitalized)
        suggestions.append(CuisineOption.american.rawValue.capitalized)
        suggestions.append(CuisineOption.japanese.rawValue.capitalized)
        return suggestions
    }

    func getRestaurantSuggestions() -> [Restaurant] {
        guard showSearchSuggestions else { return [] }
        var suggestions: [Restaurant] = []
        let search = searchText.lowercased()
        if search.contains("ita") {
            suggestions.append(contentsOf: allRestaurants.filter { $0.cuisine == .italian })
        }
        if search.contains("ja") {
            suggestions.append(contentsOf: allRestaurants.filter { $0.cuisine == .japanese })
        }
        return suggestions
    }
}

struct SearchableBootcamp: View {

    @StateObject private var viewModel = SearchableViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.filteredRestaurants) { restaurant in

                    NavigationLink(value: restaurant) {
                        // to make color not default blue we need to set foreground color for texts or .tint(.primary)
                        restaurantRow(restaurant: restaurant)
                    }
                }
            }
            .padding()
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .automatic,
            prompt: Text("Search restaurants...")
        )
        .searchScopes($viewModel.searchScope, scopes: {
            ForEach(viewModel.searchScopes, id: \.self) { scope in
                Text(scope.title)
                    .tag(scope)
            }
        })
        .searchSuggestions({
            ForEach(viewModel.getSearchSuggestions(), id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }

            ForEach(viewModel.getRestaurantSuggestions(), id: \.self) { suggestion in
                NavigationLink(value: suggestion) {
                    Text(suggestion.title)
                        .foregroundStyle(Color.green)
                }
            }
        })
        //.navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Restaurant")
        .task {
            await viewModel.loadRestaurants()
        }
        .navigationDestination(for: Restaurant.self) { restaurant in
            Text(restaurant.title.uppercased())
        }
    }

    private func restaurantRow(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.title)
                .font(.headline)
            Text(restaurant.cuisine.rawValue.capitalized)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05))
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
        SearchableBootcamp()
    }
}
