// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SearchLocationsQuery: GraphQLQuery {
  public static let operationName: String = "SearchLocations"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query SearchLocations($page: Int, $name: String) { locations(page: $page, filter: { name: $name }) { __typename info { __typename count pages next prev } results { __typename id name type dimension } } }"#
    ))

  public var page: GraphQLNullable<Int>
  public var name: GraphQLNullable<String>

  public init(
    page: GraphQLNullable<Int>,
    name: GraphQLNullable<String>
  ) {
    self.page = page
    self.name = name
  }

  public var __variables: Variables? { [
    "page": page,
    "name": name
  ] }

  public struct Data: RMServerAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { RMServerAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("locations", Locations?.self, arguments: [
        "page": .variable("page"),
        "filter": ["name": .variable("name")]
      ]),
    ] }

    /// Get the list of all locations
    public var locations: Locations? { __data["locations"] }

    /// Locations
    ///
    /// Parent Type: `Locations`
    public struct Locations: RMServerAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { RMServerAPI.Objects.Locations }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("info", Info?.self),
        .field("results", [Result?]?.self),
      ] }

      public var info: Info? { __data["info"] }
      public var results: [Result?]? { __data["results"] }

      /// Locations.Info
      ///
      /// Parent Type: `Info`
      public struct Info: RMServerAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { RMServerAPI.Objects.Info }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("count", Int?.self),
          .field("pages", Int?.self),
          .field("next", Int?.self),
          .field("prev", Int?.self),
        ] }

        /// The length of the response.
        public var count: Int? { __data["count"] }
        /// The amount of pages.
        public var pages: Int? { __data["pages"] }
        /// Number of the next page (if it exists)
        public var next: Int? { __data["next"] }
        /// Number of the previous page (if it exists)
        public var prev: Int? { __data["prev"] }
      }

      /// Locations.Result
      ///
      /// Parent Type: `Location`
      public struct Result: RMServerAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { RMServerAPI.Objects.Location }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", RMServerAPI.ID?.self),
          .field("name", String?.self),
          .field("type", String?.self),
          .field("dimension", String?.self),
        ] }

        /// The id of the location.
        public var id: RMServerAPI.ID? { __data["id"] }
        /// The name of the location.
        public var name: String? { __data["name"] }
        /// The type of the location.
        public var type: String? { __data["type"] }
        /// The dimension in which the location is located.
        public var dimension: String? { __data["dimension"] }
      }
    }
  }
}
