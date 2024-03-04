//
//  CollectionParameters.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 04.03.2024.
//

struct CollectionParameters {
    let cellsNumber: Int
    let leftInset: CGFloat
    let rightInset: CGFloat
    let interCellSpacing: CGFloat

    var widthInsets: CGFloat {
        return interCellSpacing * CGFloat(cellsNumber - 1) + leftInset + rightInset
    }
}
