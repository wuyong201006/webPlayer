package
{
	import flash.display.Sprite;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;

	public class Version
	{
		//版本
		public static function compileVersion(sprit:Sprite):void
		{
			var version:String = "Version:M3U8Player_v2.2.3_2014.11.10.18.45";
			var name:String = "DevBy:Alex/XinWang Wang";
			var conemail:String = "Contact:1669499355@qq.com";
			var company:String = "Company:天脉聚源（北京）传媒科技有限公司";
			
			var contextMenu:ContextMenu = new ContextMenu();
			contextMenu.hideBuiltInItems();
			
//			contextMenu.customItems.push(new ContextMenuItem(company));
//			contextMenu.customItems.push(new ContextMenuItem(name));
//			contextMenu.customItems.push(new ContextMenuItem(conemail));
			contextMenu.customItems.push(new ContextMenuItem(version));
			
			sprit.contextMenu = contextMenu;
		}
	}
}