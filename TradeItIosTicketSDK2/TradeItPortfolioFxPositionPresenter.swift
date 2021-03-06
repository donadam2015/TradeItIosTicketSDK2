class TradeItPortfolioFxPositionPresenter: TradeItPortfolioPositionPresenter {
    var fxPosition: TradeItFxPosition = TradeItFxPosition()
    var tradeItPortfolioPosition: TradeItPortfolioPosition

    init(_ tradeItPortfolioPosition: TradeItPortfolioPosition) {
        if let fxPosition = tradeItPortfolioPosition.fxPosition {
            self.fxPosition = fxPosition
        }
        self.tradeItPortfolioPosition = tradeItPortfolioPosition
    }

    func getFormattedSymbol() -> String {
        guard let symbol = self.fxPosition.symbol
            else { return TradeItPresenter.MISSING_DATA_PLACEHOLDER }

        return symbol
    }
    
    func getQuantity() -> NSNumber? {
        return self.fxPosition.quantity
    }

    func formatCurrency(_ currency: NSDecimalNumber) -> String {
        return NumberFormatter.formatCurrency(currency, maximumFractionDigits: TradeItPortfolioPosition.fxMaximumFractionDigits, currencyCode: getCurrencyCode())
    }

    func getFormattedQuantity() -> String {
        guard let quantity = getQuantity()
            else { return TradeItPresenter.MISSING_DATA_PLACEHOLDER }

        return NumberFormatter.formatQuantity(quantity)
    }

    func getAveragePrice() -> String {
        guard let averagePrice = self.fxPosition.averagePrice
            else { return TradeItPresenter.MISSING_DATA_PLACEHOLDER }

        return formatCurrency(averagePrice)
    }

    func getTotalUnrealizedProfitAndLossBaseCurrency() -> String {
        guard let totalUnrealizedProfitAndLossBaseCurrency = fxPosition.totalUnrealizedProfitAndLossBaseCurrency
            else { return TradeItPresenter.MISSING_DATA_PLACEHOLDER }

        return formatCurrency(totalUnrealizedProfitAndLossBaseCurrency)
    }
    
    func getQuote() -> TradeItQuote? {
        return self.tradeItPortfolioPosition.quote
    }
    
    func getHoldingType() -> String? {
        return self.fxPosition.holdingType
    }
    
    func getCurrencyCode() -> String {
        return TradeItPresenter.DEFAULT_CURRENCY_CODE
    }
}
