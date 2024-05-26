﻿
Функция RemoteQueryGet(ЗапросHTTP)
	
	ОтветHTTP = Новый HTTPСервисОтвет(200);
	
	Метод = ЗапросHTTP.ПараметрыURL.Получить("method");
	Если Метод="ping" Тогда
		Результат = вз_ВнешниеЗапросыВходящие.Пинг();
		ОтветHTTP.УстановитьТелоИзСтроки(Результат);
		
	ИначеЕсли Метод="get" Тогда
		ТелоЗапроса = ЗапросHTTP.ПолучитьТелоКакСтроку();
		Результат = вз_ВнешниеЗапросыВходящие.ВыполнитьВнешнийЗапрос(ТелоЗапроса);
		ОтветHTTP.УстановитьТелоИзСтроки(Результат);
		
	Иначе
		ОтветHTTP.КодСостояния = 404;	
	КонецЕсли;
	
	Возврат ОтветHTTP;
	
КонецФункции

