import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ClosingStockReport extends StatefulWidget {
  const ClosingStockReport({super.key});

  @override
  _ClosingStockReportState createState() => _ClosingStockReportState();
}

class _ClosingStockReportState extends State<ClosingStockReport> {
  List<StockData> stockData = [
    StockData("Flour", 100, 30, 5, 65),
    StockData("Cheese", 80, 20, 10, 50),
    StockData("Tomato", 50, 15, 2, 33),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Closing Stock Report")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stock Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: stockData.length,
                itemBuilder: (context, index) {
                  final stock = stockData[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(stock.ingredient),
                      subtitle: Text(
                          "Purchased: ${stock.totalPurchased} | Used: ${stock.totalUsed} | Wasted: ${stock.totalWasted} | Closing: ${stock.closingStock}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Stock Movement Chart",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                legend: const Legend(isVisible: true),
                series: <CartesianSeries>[
                  ColumnSeries<StockData, String>(
                    name: "Purchased",
                    dataSource: stockData,
                    xValueMapper: (StockData data, _) => data.ingredient,
                    yValueMapper: (StockData data, _) => data.totalPurchased,
                    color: Colors.blue,
                  ),
                  ColumnSeries<StockData, String>(
                    name: "Used",
                    dataSource: stockData,
                    xValueMapper: (StockData data, _) => data.ingredient,
                    yValueMapper: (StockData data, _) => data.totalUsed,
                    color: Colors.orange,
                  ),
                  ColumnSeries<StockData, String>(
                    name: "Wasted",
                    dataSource: stockData,
                    xValueMapper: (StockData data, _) => data.ingredient,
                    yValueMapper: (StockData data, _) => data.totalWasted,
                    color: Colors.red,
                  ),
                  ColumnSeries<StockData, String>(
                    name: "Closing Stock",
                    dataSource: stockData,
                    xValueMapper: (StockData data, _) => data.ingredient,
                    yValueMapper: (StockData data, _) => data.closingStock,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockData {
  final String ingredient;
  final int totalPurchased;
  final int totalUsed;
  final int totalWasted;
  final int closingStock;

  StockData(this.ingredient, this.totalPurchased, this.totalUsed,
      this.totalWasted, this.closingStock);
}
