/// <reference path="../../libs/LayaAir.d.ts" />
var laya;
(function (laya) {
    var Stage = laya.display.Stage;
    var Text = laya.display.Text;
    var Browser = laya.utils.Browser;
    var WebGL = laya.webgl.WebGL;
    var Timer_CallLater = (function () {
        function Timer_CallLater() {
            // 不支持WebGL时自动切换至Canvas
            Laya.init(Browser.clientWidth, Browser.clientHeight, WebGL);
            Laya.stage.alignV = Stage.ALIGN_MIDDLE;
            Laya.stage.alignH = Stage.ALIGN_CENTER;
            Laya.stage.scaleMode = Stage.SCALE_SHOWALL;
            Laya.stage.bgColor = "#232628";
            this.demonstrate();
        }
        Timer_CallLater.prototype.demonstrate = function () {
            for (var i = 0; i < 10; i++) {
                Laya.timer.callLater(this, this.onCallLater);
            }
        };
        Timer_CallLater.prototype.onCallLater = function () {
            console.log("onCallLater triggered");
            var text = new Text();
            text.font = "SimHei";
            text.fontSize = 30;
            text.color = "#FFFFFF";
            text.text = "打开控制台可见该函数仅触发了一次";
            text.size(Laya.stage.width, Laya.stage.height);
            text.wordWrap = true;
            text.valign = "middle";
            text.align = "center";
            Laya.stage.addChild(text);
        };
        return Timer_CallLater;
    }());
    laya.Timer_CallLater = Timer_CallLater;
})(laya || (laya = {}));
new laya.Timer_CallLater();
