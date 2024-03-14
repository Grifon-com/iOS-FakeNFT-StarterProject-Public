import XCTest
import FakeNFT

final class ProfileUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = XCUIApplication()
        app.launch()
        
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        app.terminate()
        app = nil
    }
    
    func testEditButton() {
        sleep(15)
        
        let profileVc = app.images["ProfileView"]
        
        app.buttons["editProfileButton"].tap()
        
        sleep(2)
        
        let editVc = app.images["EditView"]
        
        XCTAssertFalse(profileVc == editVc)
    }
    
    func testMyNftCell() {
        sleep(5)

        let profileVc = app.images["ProfileView"]

        let table = app.tables.matching(identifier: "ProfileTable")

        let cell = table.cells.element(matching: .cell, identifier: "MyNftCell")

        cell.tap()

        sleep(10)

        let myNftVc = app.images["MyNftView"]

        sleep(1)

        XCTAssertFalse(profileVc == myNftVc)
    }
    
    func testFavoriteCell() {
        sleep(5)
        
        let profileVc = app.images["ProfileView"]
        
        let table = app.tables.matching(identifier: "ProfileTable")

        let cell = table.cells.element(matching: .cell, identifier: "FavoriteCell")

        cell.tap()

        sleep(10)

        let favoriteVc = app.images["FavoriteView"]

        sleep(1)

        XCTAssertFalse(profileVc == favoriteVc)
    }
    
    func testDevelopCell() {
        sleep(5)
        
        let profileVc = app.images["ProfileView"]
        
        let table = app.tables.matching(identifier: "ProfileTable")

        let cell = table.cells.element(matching: .cell, identifier: "DevelopCell")

        cell.tap()

        sleep(10)

        let developVc = app.images["ProfileWebView"]

        sleep(1)

        XCTAssertFalse(profileVc == developVc)
    }
}
