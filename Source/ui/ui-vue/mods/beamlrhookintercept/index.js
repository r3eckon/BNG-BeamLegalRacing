//BeamLR Hook Interceptor VUE script, receives route data from lua, sends it to lua
//so that it can be modified (ex: to disable some buttons) then sent back to UI.
//Roundabout way of doing this but simplest method to avoid modifying vanilla scripts.

//boilerplate code for beamng stuff
import { useBridge } from "@/bridge"
const { lua, events } = useBridge()

//event callback function
function onRouteDataReceived(payload){
	//encode as b64 to avoid json formatting issues with certain characters that 
	//could be found in various UI strings for menu labels like ' 
	
	//could optimize here by checking if data is modified already and just not send it back
	//instead of doing it in lua after data is received again
	var encoded = btoa(JSON.stringify(payload))
	bngApi.engineLua(`extensions.blrutils.routerDataHandler('${encoded}')`)
}

export async function onLoad() {
  //Start listening to routeData event to send it back to lua
  events.on("ui_router_routeData", payload => {onRouteDataReceived(payload)})
}

export async function onUnload() {
  //Stop listening
  events.off("ui_router_routeData")
}