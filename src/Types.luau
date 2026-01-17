local BakeryVideTypes = {}

export type action = (
	(Instance) -> (),
	priority: number?
) -> {
	priority: number,
	callback: (Instance) -> (),
}

export type child =
	Instance
	| (() -> child?) -- 반응적으로 자식을 바꾸고 싶을 때
	| { [number]: child } -- 트리 (배열처럼)
	| action

export type function props(props: type)
	-- 원본 Props의 각 프로퍼티를 T | (() -> T) 로 변환
	for key, prop in props:properties() do
		props:setproperty(
			key,
			types.unionof(prop.read, types.newfunction({}, { head = { prop.read } }))
		)
	end

	props:setindexer(types.number, types.any)

	return props
end


export type prop<T> = T | () -> T

return BakeryVideTypes
