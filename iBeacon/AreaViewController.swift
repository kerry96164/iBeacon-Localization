//
//  AreaViewController.swift
//  iBeacon
//
//  Created by Kerry Lu on 2024/4/23.
//

import UIKit
import CoreLocation
import DGCharts
/*
//for chart
struct RssiData :Identifiable{
    let id = UUID()
    let rssi: Array<Double?>
    
    init(rssiList: Array<Double?>){
        self.rssi = rssiList
    }
}*/


class AreaViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var monitorResultTextView: UITextView!
    @IBOutlet weak var rangingLabel: UILabel!
    @IBOutlet weak var beaconNumberLabel: UILabel!
    @IBOutlet weak var rangingResultTextView: UITextView!

    @IBOutlet weak var rssiRecordTextView: UITextView!
    @IBOutlet weak var avgRssiTextView: UILabel!
    @IBOutlet weak var newXYField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sectionResultButton: UIButton!
    @IBOutlet weak var coordinateResultLabel: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!
    //@IBOutlet weak var areaMapView: UIView!
    //@IBOutlet weak var positionMarkerView: UIImageView!
    //@IBOutlet weak var areaMapImageView: UIImageView!
    
    var areaLocationManager: CLLocationManager = CLLocationManager()
    
    let uuid = "A3E1C063-9235-4B25-AA84-D249950AADC4"
    let identifier = "area-location"
    let major: CLBeaconMajorValue = 1
    //ibeacon個數
    let numberOfBeacon = 4
    //地圖長寬
    //let mapX = 4.3
    //let mapY = 11.75

    //區域分界
    let abY = 7.21
    let bcY = 2.67
    //rssiListArray:包含最多numnerOfRssi筆資料，每筆資料rssiList為所有接收之rssi
    let numnerOfRssi = 10
    //K-Nearest
    let K = 10
    let maxDistance:Double = 2 //m
    
    let fileName = "area-location_data.txt"
    
    var rssiListArray: Array<Array<Double?>> = []
    //avgRssiList
    var avgRssiList :Array<Double?> = []
    //包含座標及對應之RSSI的Dictionary array
    var referencePointArray = [[String:Any]]()
    //是否執行定位，由sectionResultButton控制
    var doPositioning = false
    //for Linechart line color
    var lineColor = [UIColor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("areaViewDidLoad")
        //顯示介面處理及初始化資料
        sectionResultButton.layer.cornerRadius = 5
        sectionResultButton.layer.masksToBounds = true
        sectionResultButton.backgroundColor = .lightGray
        setSectionResultBrttonText(text: "X")
        //positionMarkerView.translatesAutoresizingMaskIntoConstraints = true
        //positionMarkerView.tintColor = .lightGray
        
        rssiRecordTextView.text = ""
        avgRssiList = Array(repeating: nil, count: numberOfBeacon)
        setLineChartViewConfig()
        loadDataArray()

        //要求使用者授權location
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
            if CLLocationManager().authorizationStatus != CLAuthorizationStatus.authorizedAlways{
                areaLocationManager.requestWhenInUseAuthorization()
            }
        }
        doMonitoring(true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("areaViewWillDisappear")
        //doMonitoring(false)
        //clearRssiRecord(self)
        //areaLocationManager.stopUpdatingLocation()
        //areaLocationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID.init(uuidString: uuid)!, major: major))
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("areaViewDidAppear")
        clearRssiRecord(self)
        //doMonitoring(true)
        //areaLocationManager.startUpdatingLocation()
        //areaLocationManager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID.init(uuidString: uuid)!, major: major))
    }
    //initial regine and do monitoring?
    func doMonitoring(_ state:Bool){
        //建立region
        let region = CLBeaconRegion(uuid: UUID.init(uuidString: uuid)!, major: major, identifier: identifier)
        
        //設定location manager的delegate
        areaLocationManager.delegate = self
        //設定region monitoring要被通知的時機
        region.notifyEntryStateOnDisplay = true
        region.notifyOnEntry = true
        region.notifyOnExit = true
        print("Area:\(areaLocationManager)")
        //start monitoring
        if state {
            areaLocationManager.startMonitoring(for: region)
        }else{
            areaLocationManager.stopMonitoring(for: region)
        }
    }
    
    

    //start
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        if region.identifier==identifier{
            print("START: \(region.identifier)")
            monitorResultTextView.text = "[Start Monitoring] \(region.identifier)\n" + monitorResultTextView.text
        }
    }
    //enter region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        print("ENTER: \(region.identifier)")
        if region.identifier==identifier{
            monitorResultTextView.text = "Enter region\n" + monitorResultTextView.text
        }
    }
    //exit region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier==identifier{
            print("EXIT: \(region.identifier)")
            monitorResultTextView.text = "Exit regine\n" + monitorResultTextView.text
        }
    }
    //region state
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region.identifier==identifier{
            print("STATE: \(region.identifier)")
            switch state{
            case .inside:
                monitorResultTextView.text = "[State Inside] Start Ranging\n" + monitorResultTextView.text
                //如果裝置支援RangingBeacons，開始Ranging region
                areaLocationManager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID.init(uuidString: uuid)!, major: major))
               
                rangingLabel.textColor = .black
                rangingResultTextView.textColor = .black
            case .outside:
                monitorResultTextView.text = "[State Outside] Stop Ranging\n" + monitorResultTextView.text
                //停止Ranging region
                areaLocationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID.init(uuidString: uuid)!, major: major))
                rangingLabel.textColor = .lightGray
                rangingResultTextView.textColor = .lightGray
            default:
                break
            }
        }
    }
    
    //delegate method, 收到beacon訊號, 透過delegate通知App
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion){
        print("Delegate: \(region.major.debugDescription)")
        if region.major?.uint16Value == major{
            var rssiList :Array<Double?> = Array(repeating: nil, count: numberOfBeacon)
            //清空原本的ranging textview
            rangingResultTextView.text = ""
            
            //minor排序
            let orderBeaconArray = beacons.sorted(by: { (b1, b2) -> Bool in return b2.minor.intValue > b1.minor.intValue })
            //let orderBeaconArray = beacons
            //iterate每個收到的beacons
            var index = 1
            for beacon in orderBeaconArray{
                if beacon.major.intValue == Int(major) {
                    var proximityString = ""
                    switch beacon.proximity{
                    case .immediate:
                        proximityString = "Immediate"
                    case .near:
                        proximityString = "Near"
                    case .far:
                        proximityString = "Far"
                    default :
                        proximityString = "Unknown"
                    }
                    rangingResultTextView.text = rangingResultTextView.text + """
                                            [\(index)]
                                            Major: \(beacon.major)
                                            Minor: \(beacon.minor)
                                            RSSI: \(beacon.rssi)
                                            Proximity: \(proximityString)
                                            Accuracy: \(beacon.accuracy)\n
                                            """
                    if(beacon.minor.intValue > numberOfBeacon){
                        monitorResultTextView.text = "[!]非法Beacon \(beacon.major)-\(beacon.minor)\n" + monitorResultTextView.text
                    }else{
                        var rssi: Double? = Double(beacon.rssi)
                        if rssi == 0{
                            rssi = nil
                        }
                        rssiList[beacon.minor.intValue-1] = rssi
                    }
                    beaconNumberLabel.text = "\(index)"
                    if index > numberOfBeacon{
                        beaconNumberLabel.textColor = .red
                    }else{
                        beaconNumberLabel.textColor = .black
                    }
                    index+=1
                }
            }
            addRssiRecord(rssiList: rssiList)
        }
    }
    //Input:RSSI List(各rssi)
    //將此筆RSSI資料加入rssiListArray，並顯示在rssiRecordTextView
    //更新平均，在avgRssiTextView顯示
    func addRssiRecord(rssiList:Array<Double?>){
        //將此筆RSSI資料加入rssiListArray
        rssiListArray.insert(rssiList, at: 0)
        /*if rssiListArray.count > 10{
            rssiListArray.removeFirst()
        }*/
        //顯示在rssiRecordTextView
        rssiRecordTextView.text = "\(rssiListToText(rssiList: rssiList))\n" + rssiRecordTextView.text
        updateChart()
        //rssiListArray有numberOfBeacon筆資料，更新平均並在avgRssiTextView顯示
        if rssiListArray.count >= numnerOfRssi {
            avgRssiList = Array(repeating: nil, count: numberOfBeacon)
            for j in 0...numberOfBeacon-1{
                var n = 0.0
                for i in 0..<numnerOfRssi{
                    if let rssi = rssiListArray[i][j], let sum = avgRssiList[j]{
                        if rssi.isNaN{continue}
                        n+=1
                        avgRssiList[j] = rssi + sum
                    }else if let rssi = rssiListArray[i][j]{
                        if rssi.isNaN{continue}
                        n+=1
                        avgRssiList[j] = rssi
                    }
                }
                if let sum = avgRssiList[j]{
                    avgRssiList[j] = sum / n
                }
            }
            //顯示在avgRssiTextView
            avgRssiTextView.text = "\(rssiListToText(rssiList: avgRssiList))"
            
            //如果doPositioning為true，呼叫positioning判斷目前座標
            if doPositioning && !avgRssiList.allSatisfy({$0==nil}){
                var resultX:Double?
                var resultY:Double?
                do{
                    (resultX,resultY) = try positioning(unknowRssiList: avgRssiList)
                    determineArea(resultX: resultX, resultY: resultY)
                    coordinateResultLabel.text = String(format: "%2.2f", resultX ?? -1.0) + ", " + String(format: "%2.2f", resultY ?? -1.0)
                }catch{
                    monitorResultTextView.text = "[!]定位失敗\n" + monitorResultTextView.text
                    print(error)
                }
            }
        }
        
    }
    //------------Linechart----------
    func updateChart(){
        let data = LineChartData()
        for i in 0..<numberOfBeacon{
            print(i)
            var chartEntry = [ChartDataEntry]()
            for j in 0..<rssiListArray.count{
                if let r = rssiListArray[j][i]{
                    let value = ChartDataEntry(x: Double(j), y: r)
                    chartEntry.append(value)
                }
            }
            let dataSet = LineChartDataSet(entries: chartEntry, label: "\(i+1)")
            dataSet.drawCirclesEnabled = false
            dataSet.drawValuesEnabled = false
            dataSet.mode = .horizontalBezier
            dataSet.highlightEnabled = false
            dataSet.lineWidth = 3
            dataSet.colors = [lineColor[i]]
            print(lineColor[i])
            data.append(dataSet)
        }
        lineChartView.data = data
        lineChartView.chartDescription.text = "RSSI"
        
    }
    
    func setLineChartViewConfig(){
        lineColor = randomColorArray(number: numberOfBeacon)
        lineChartView.dragEnabled = false
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.scaleXEnabled = false
        lineChartView.scaleYEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
    }
    func randomColorArray(number:Int)->[UIColor]{
        var colorArray = [UIColor]()
        for n in 1...number{
            let red = CGFloat(Int.random(in: 0...256))/255.0
            let green = CGFloat(Int.random(in: 0...256))/255.0
            let blue = CGFloat(Int.random(in: 0...256))/255.0
            colorArray.append(UIColor(red: red, green: green, blue: blue, alpha: 1.0))
        }
        return colorArray
    }
    //------------End of Linechart----------
    
    //
    func determineArea(resultX:Double?,resultY:Double?){
        if let y = resultY{
            if y>=abY{
                setSectionResultBrttonText(text: "A")
            }else if y>=bcY{
                setSectionResultBrttonText(text: "B")
            }else{
                setSectionResultBrttonText(text: "C")
            }
        }else{
            monitorResultTextView.text = "[!]Area判斷失敗\n" + monitorResultTextView.text
        }
    }
    /*
    func updatePositionMarker(resultX:Double?,resultY:Double?){
        if let rX = resultX, let rY = resultY{
            positionMarkerView.tintColor = .systemBlue
            let mapViewWidth = areaMapView.frame.width
            let mapViewHeight = areaMapView.frame.height
            let markerWidth = positionMarkerView.frame.width
            let markerHeight = positionMarkerView.frame.height
            let markerX = Int(rX/mapX*mapViewWidth - markerWidth/2)
            let markerY = Int(mapViewHeight - rY/mapY*mapViewHeight - markerHeight/2)
            print("\(markerX),\(markerY)")
            positionMarkerView.center = CGPoint(x: markerX, y: markerY)
        }
    }*/
    
    //將Array<Double?>轉成String回傳
    func rssiListToText(rssiList:Array<Double?>) -> String{
        var newtext :[String] = [String]()
        for rssi in rssiList{
            if let r = rssi{
                newtext.append(String(format: "%2.1f", r))
            }else{
                newtext.append("nan")
            }
        }
        return newtext.joined(separator: " , ")
    }
        
    //清除 Button:清除RSSI紀錄(rssiRecordTextView, rssiListArray)
    @IBAction func clearRssiRecord(_ sender: Any) {
        rssiRecordTextView.text = ""
        rssiListArray.removeAll()
        avgRssiList = Array(repeating: nil, count: numberOfBeacon)
        avgRssiTextView.text = ""
    }
    
    //Add Button:新增目前紀錄之rssi及XY座標
    @IBAction func addCoordinateButton(_ sender: Any) {
        if addCoordinateWithAvgRssi(){
            //輸入失敗
            newXYField.isError(numberOfShakes: 2, revert: true)
        }
    }
    @IBAction func newXYFieldAction(_ sender: Any) {
        if addCoordinateWithAvgRssi(){
            //輸入失敗
            newXYField.isError(numberOfShakes: 2, revert: true)
        }
    }
    
    //新增至coordinateWithRssiArray，有錯回傳true
    func addCoordinateWithAvgRssi() -> Bool {
        guard let newCoordinateString = newXYField.text, !newCoordinateString.isEmpty else {return true}
        let newXYStringArray = newCoordinateString.components(separatedBy: ",")
        if newXYStringArray.count != 2 {return true}
        guard let newX = Double(newXYStringArray[0]) else {return true}
        guard let newY = Double(newXYStringArray[1]) else {return true}
        referencePointArray.insert(["X":newX,"Y":newY,"RSSI":avgRssiList], at: 0)
        newXYField.text = ""
        tableView.reloadData()
        saveData()
        return false
    }
    
    
    //------實作Table View------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return referencePointArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //從storyboard中的table view尋找有identifier為"Basic Cell"的cell範例
        //且如果之前有相同identifier的Cell被宣告出來且沒在使用的話，重複使用，節省記憶體
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic Cell", for: indexPath)
        //設定Cell的內容
        let X = referencePointArray[indexPath.row]["X"] as? Double ?? -1.0
        let Y = referencePointArray[indexPath.row]["Y"] as? Double ?? -1.0
        cell.textLabel?.text = "(\(X),\(Y))"
        cell.detailTextLabel?.text = rssiListToText(rssiList: referencePointArray[indexPath.row]["RSSI"] as! Array<Double?>)
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //啟用所有row的edit功能
        return true
    }
    func tableView(_ tableView: UITableView,commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            referencePointArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .top)
            saveData()
        default:
            break

        }
    }//------End--實作Table View------`
    
    //------資料存取------
    func saveData(){
        var finalString = "" //X,Y,Rssi1,Rssi2,...
        for dict in referencePointArray{
            let X = dict["X"] as? Double ?? -1.0
            let Y = dict["Y"] as? Double ?? -1.0
            let rssi = rssiListToText(rssiList: dict["RSSI"] as! Array<Double?>)
            finalString += "\(X),\(Y)," + rssi + "\n"
        }
        writeStringToFile(writeString: finalString, fileName: fileName)
    }
    //儲存字串
    func writeStringToFile(writeString: String, fileName:String){
        //取得app專用資料夾路徑，並確定檔案路徑存在
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else{ return }
        //在路徑後加入檔名，組合成要寫入的檔案路徑
        let fileURL = dir.appendingPathComponent(fileName)
        do{
            try writeString.write(to: fileURL, atomically: false, encoding: .utf8)
        }catch{
            monitorResultTextView.text = "[!]資料儲存失敗\n" + monitorResultTextView.text
        }
    }
    func loadDataArray(){
        var finalArray = [[String:Any]]()
        let csvString = readFileToString(fileName: fileName)
        let stringWithOutSapce = csvString.replacingOccurrences(of: " ", with: "")
        let lineOfString = stringWithOutSapce.components(separatedBy: "\n")
        for line in lineOfString{
            let itemArray = line.components(separatedBy: ",")
            if itemArray.count == numberOfBeacon+2 {
                let X = Double(itemArray[0])
                let Y = Double(itemArray[1])
                var rssiList :Array<Double?> = Array(repeating: nil, count: numberOfBeacon)
                for i in 0..<numberOfBeacon{
                    rssiList[i] = Double(itemArray[i+2])
                }
                finalArray.insert(["X":X ?? -1.0,"Y":Y ?? -1.0,"RSSI":rssiList], at: 0)
            }
        }
        referencePointArray = finalArray
        tableView.reloadData()
    }
    //讀取字串
    func readFileToString(fileName: String) -> String {
        //取得app專用資料夾路徑，並確定檔案路徑存在
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else{ return ""}
        //在路徑後加入檔名，組合成要寫入的檔案路徑
        let fileURL = dir.appendingPathComponent(fileName)
        var readString = ""
        do{
            try readString = String.init(contentsOf: fileURL, encoding: .utf8)
        }catch{
            monitorResultTextView.text = "[!]資料讀取失敗\n" + monitorResultTextView.text
        }
        return readString
    }
    //------End--資料存取------
    //改變結果按鈕文字
    func setSectionResultBrttonText(text:String){
        if let attrFont = UIFont(name:"Helvetica",size: 80){
            let attrTitle = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font :attrFont])
            sectionResultButton.setAttributedTitle(attrTitle, for: .normal)
        }
    }
    
    //--------定位--------
    //是否執行定位的開關
    @IBAction func sectionResultButton(_ sender: Any) {
        if doPositioning{
            sectionResultButton.backgroundColor = .lightGray
            setSectionResultBrttonText(text: "X")
            doPositioning = false
        }else{
            sectionResultButton.backgroundColor = .systemBlue
            setSectionResultBrttonText(text: "X")
            doPositioning = true
        }
    }
    
    func positioning(unknowRssiList:Array<Double?>)throws -> (Double?, Double?){
        print("----unknowRssiList----")
        print(unknowRssiList)
        print("----referencePointArray----")
        print(referencePointArray)
        var resultX: Double? = nil
        var resultY: Double? = nil
        let selectedKNNpoints = findKNearest(unknowRssiList: unknowRssiList)
        print("----selectedKNNpoints----")
        print(selectedKNNpoints)
        let selectPoints = try selectArea(selectedPoints: selectedKNNpoints)
        print("----selectPoints----")
        print(selectPoints)
        (resultX, resultY) = weightMeanPosition(unknowRssiList: unknowRssiList, selectPoint: selectPoints)
        return (resultX, resultY)
    }
    
    func weightMeanPosition(unknowRssiList: Array<Double?>, selectPoint: [[String:Any]]) -> (Double, Double){
        var resultX = 0.0
        var resultY = 0.0
        var weightArray = [Double]()
        var weightSum = 0.0
        for point in selectPoint{
            let referenceRssiList = point["RSSI"] as! Array<Double?>
            var dist = distenceOfRssiArray(array1: unknowRssiList, array2: referenceRssiList)
            dist = 1/pow(10, dist)
            weightArray.append(dist)
            weightSum += dist
        }
        weightArray = weightArray.map{Double($0)/weightSum}
        for (weight,point) in zip(weightArray,selectPoint){
            resultX += weight * (point["X"] as! Double)
            resultY += weight * (point["Y"] as! Double)
        }
        return (resultX, resultY)
    }

    func selectArea(selectedPoints :[[String:Any]])throws -> [[String:Any]]{
        var selectedClass = [[String:Any]]()
        var classes = [[[String:Any]]]() //A empty list for each class
        for element in selectedPoints{
            var tempClass = [[String:Any]]() //A empty list for each class
            tempClass.append(element) //Add center of each point to each class
            classes.append(tempClass) //Addthe created class to list of classes
        }
        var tempClasses = [[[String:Any]]]()
        for cl in classes{
            var tempClass = cl
            for element in selectedPoints{
                var dist: Double = 999
                if !NSDictionary(dictionary: element).isEqual(to: cl[0]){
                    var array1 = Array<Double?>()
                    var array2 = Array<Double?>()
                    let x1 = cl[0]["X"] as? Double ?? -1.0
                    let y1 = cl[0]["Y"] as? Double ?? -1.0
                    array1 = [x1,y1]
                    let x2 = element["X"] as? Double ?? -1.0
                    let y2 = element["Y"] as? Double ?? -1.0
                    array2 = [x2,y2]
                    dist = distenceOfXYArray(array1: array1, array2: array2)
                }
                if dist <= maxDistance {
                    tempClass.append(element)
                }
            }
            tempClasses.append(tempClass)
        }
        classes = tempClasses
        if classes.count == 0 {throw iBeacon.positioning.nullClass }
        selectedClass = classes[0]
        for element in classes{
            if element.count > selectedClass.count{
                selectedClass = element
            }
        }
        return selectedClass
    }
    
    func findKNearest(unknowRssiList:Array<Double?>) -> [[String:Any]]{
        var kNearest = [[String:Any]]()
        var distanceOfReferencePointArray = [Double:[String:Any]]()
        //算出到參考點的RSSI距離，當成dict的key
        for refernencePoint in referencePointArray{
            let dist = distenceOfRssiArray(array1: refernencePoint["RSSI"] as! Array<Double?>, array2: unknowRssiList)
            if dist.isNaN {continue}
            var pointWithDistance = refernencePoint
            pointWithDistance["Dist"] = dist
            distanceOfReferencePointArray[dist] = pointWithDistance
        }
        let sortedKey = distanceOfReferencePointArray.keys.sorted(by: <)
        let n = min(K,sortedKey.count)
        let firstNkey = sortedKey.prefix(n)
        for i in 0..<n {
            kNearest.append(distanceOfReferencePointArray[firstNkey[i]]!)
        }
        return kNearest
    }
    
    //計算兩Rssi array的歐式距離
    func distenceOfRssiArray(array1:Array<Double?>, array2:Array<Double?>) -> Double{
        var dist: Double = 0.0
        var n = 0.0
        for i in 0..<array1.count{
            if let a = array1[i] , let b = array2[i] {
                if a.isNaN || b.isNaN {continue}
                n += 1
                dist = pow(abs(a-b), 2) + dist
            }
        }
        print("------RSSIdist------")
        print(array1)
        print(array2)
        dist = sqrt(dist)/pow(n, 2)
        print("Dist: \(dist)")
        return dist
    }
    
    //計算兩座標的歐式距離
    func distenceOfXYArray(array1:Array<Double?>, array2:Array<Double?>) -> Double{
        var dist: Double = 0.0
        for i in 0..<array1.count{
            if let a = array1[i], let b = array2[i] {
                if a.isNaN || b.isNaN {continue}
                dist = pow(abs(a-b), 2) + dist
            }
        }
        dist = sqrt(dist)
        print("------XYdist------")
        print(array1)
        print(array2)
        print("Dist: \(dist)")
        return dist
    }
    
    //-------End-定位--------

    
}

//輸入錯誤動畫，TextField晃動
extension UITextField {
    func isError(numberOfShakes shakes: Float, revert: Bool) {
        let shake: CABasicAnimation = CABasicAnimation(keyPath: "position")
        shake.duration = 0.07
        shake.repeatCount = shakes
        if revert { shake.autoreverses = true  } else { shake.autoreverses = false }
        shake.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        shake.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(shake, forKey: "position")
    }
}

enum positioning : Error{
    case nullClass
}
