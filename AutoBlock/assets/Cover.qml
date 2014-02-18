import bb.cascades 1.0
import com.canadainc.data 1.0

Container {
    background: back.imagePaint
    topPadding: 10
    leftPadding: 10
    rightPadding: 10
    bottomPadding: 10
    horizontalAlignment: HorizontalAlignment.Fill
    verticalAlignment: VerticalAlignment.Fill

    layout: DockLayout {}

    attachedObjects: [
        ImagePaintDefinition {
            id: back
            imageSource: "images/cover_bg.png"
        }
    ]
    
    ImageView {
        imageSource: "images/logo.png"
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
    }
    
    Container {
        background: Color.Black
        opacity: 0.6
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
    }

    Label {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Center
        textStyle.base: SystemDefaults.TextStyles.SubtitleText
        textStyle.textAlign: TextAlign.Center
        textStyle.color: Color.White
        multiline: true
        
        function onDataLoaded(id, data)
        {
            if (id == QueryId.FetchAllLogs || id == QueryId.ClearLogs) {
                text = data.length == 0 ? qsTr("No spam messages detected yet...") : qsTr("%n messages blocked.", "", data.length);
            } else if (id == QueryId.FetchLatestLogs && data.length > 0) {
                text = qsTr("Last Message Blocked from:\n%1").arg( data[data.length-1].address );
            }
        }
        
        onCreationCompleted: {
            helper.dataReady.connect(onDataLoaded);
            helper.fetchAllLogs();
        }
    }
}