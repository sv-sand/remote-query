﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Внешние запросы.
// Светлаков А. В., 09.02.2023
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область СлужебныйПрограммныйИнтерфейс

// Возвращает результат проверки связи
//
// Возвращаемое значение:
//   - Строка - Исходящий запрос 
//
Функция Пинг() Экспорт

	Результат = СтрШаблон(
		"Successful connection!
		|Subsystem version %1
		|Protocol version %2",
		вз_ВнешниеЗапросы.ВерсияПодсистемы(),
		вз_ВнешниеЗапросы.ВерсияПротокола());
	
	Возврат Результат;
	
КонецФункции

// Возвращает результат выполнения внешнего запроса
//
// Параметры:
//  ТелоЗапроса - Строка - JSON строка, тело входящего HTTP запроса
// 
// Возвращаемое значение:
//   Строка - JSON строка, тело ответного HTTP запроса 
//
Функция ВыполнитьВнешнийЗапрос(ТелоЗапроса) Экспорт
	
	Попытка
		ВходящийПакет = ПакетИзJSON(ТелоЗапроса);
	Исключение
	    Возврат ОтветСОшибкой("Ошибка разбора JSON сообщения: " + ОписаниеОшибки());
	КонецПопытки;
	
	ЗарегистрироватьНовыйПакетВЖурнале(ВходящийПакет);
	
	Если ВходящийПакет.ver <> вз_ВнешниеЗапросы.ВерсияПротокола() Тогда
		ТекстОшибки = СтрШаблон(
			"Не поддерживаемая версия протокола обмена %1, поддерживается версия %2", 
			ВходящийПакет.ver, 
			вз_ВнешниеЗапросы.ВерсияПротокола());		
		Возврат ОтветСОшибкой(ТекстОшибки);
	КонецЕсли;
	
	// Подготавливаем ответ
	Попытка		
		
		Если ВходящийПакет.contentType = вз_ВнешниеЗапросыСлужебный.ТипСодержимогоЗапросИзСправочника() Тогда				
			Данные = ПолучитьРезультатЗапросаИзСправочника(ВходящийПакет.content);		
			
		ИначеЕсли ВходящийПакет.contentType = вз_ВнешниеЗапросыСлужебный.ТипСодержимогоПроизвольныйЗапрос() Тогда
			Данные = ПолучитьРезультатПроизвольногоЗапроса(ВходящийПакет.content);		
			
		Иначе
			ВызватьИсключение "Не известный тип запроса";
		КонецЕсли;
			
	Исключение
	    Возврат ОтветСОшибкой(ОписаниеОшибки());
	КонецПопытки;
	
	ОтветныйПакет = вз_ВнешниеЗапросыСлужебный.ТранспортныйПакет( 
		вз_ВнешниеЗапросыСлужебный.ТипСодержимогоРезультатЗапроса(), Данные);
	
	РезультатJSON = вз_ВнешниеЗапросыСлужебный.ОбъектВJSON(ОтветныйПакет);
	
	Возврат РезультатJSON;
	
КонецФункции

#КонецОбласти

#Область ТрансортныйУровень

Функция ПакетИзJSON(ТелоЗапроса)

	ВходящийПакет = вз_ВнешниеЗапросыСлужебный.ОбъектИзJSON(ТелоЗапроса);
	вз_ВнешниеЗапросыСлужебный.ПроверитьТранспортныйПакет(ВходящийПакет);
	
	Возврат ВходящийПакет;
	
КонецФункции

Процедура ЗарегистрироватьНовыйПакетВЖурнале(ВходящийПакет)
	
	Текст = СтрШаблон("Принят внешний запрос '%1': база отправитель '%2', пользователь '%3'",
		ВходящийПакет.contentType,
		ВходящийПакет.sender,
		ВходящийПакет.user);
	
	вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Информация, "Входящий");	
		
КонецПроцедуры

Функция ОтветСОшибкой(ТекстОшибки)

	вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(ТекстОшибки, УровеньЖурналаРегистрации.Ошибка, "Входящий");
	
	ОтветныйПакет = вз_ВнешниеЗапросыСлужебный.ТранспортныйПакет( 
		вз_ВнешниеЗапросыСлужебный.ТипСодержимогоРезультатЗапроса());
		
	ОтветныйПакет.error = Истина;	
	ОтветныйПакет.errorDescription = ТекстОшибки;	
		
	РезультатJSON = вз_ВнешниеЗапросыСлужебный.ОбъектВJSON(ОтветныйПакет);
	
	Возврат РезультатJSON;
	
КонецФункции

#КонецОбласти

#Область УровеньДанных

Функция ПолучитьРезультатЗапросаИзСправочника(Данные)

	Если НЕ вз_ВнешниеЗапросыСлужебный.ИспользоватьВнешниеЗапросыИзСправочника() Тогда
		ВызватьИсключение "Запрещено использование внешних запросов из справочника";
	КонецЕсли;	
	
	ИдентификаторЗапроса = ПолучитьИдентификаторЗапроса(Данные);
	ВнешнийЗапрос = ПолучитьВнешнийЗапрос(ИдентификаторЗапроса);
	
	ПараметрыЗапроса = ПолучитьПараметрыЗапроса(Данные);
	ДополнитьПараметрыЗапросаИзСправочника(ВнешнийЗапрос, ПараметрыЗапроса);
	
	Если ВнешнийЗапрос.Вид = Перечисления.вз_ВидыВнешнихЗапросов.Запрос Тогда
		Результат = ВыполнитьЗапрос(ВнешнийЗапрос.ТекстЗапроса, ПараметрыЗапроса);
	
	ИначеЕсли ВнешнийЗапрос.Вид = Перечисления.вз_ВидыВнешнихЗапросов.Код Тогда
		Результат = ВыполнитьКодЗапроса(ВнешнийЗапрос.ИсполняемыйКод, ПараметрыЗапроса);	
		
	Иначе	
		ВызватьИсключение "Не корректный вид внешнего запроса";
	КонецЕсли;
	
	Если ТипЗнч(Результат) = Тип("ТаблицаЗначений") Тогда
		Результат = ТаблицаВМассивСтруктур(Результат);
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

Функция ПолучитьРезультатПроизвольногоЗапроса(Данные)

	Если НЕ вз_ВнешниеЗапросыСлужебный.ИспользоватьПроизвольныеВнешниеЗапросы() Тогда
		ВызватьИсключение "Запрещено использование произвольных внешних запросов";
	КонецЕсли;
	
	ПараметрыЗапроса = ПолучитьПараметрыЗапроса(Данные);	
	
	ТекстЗапроса = ПолучитьТекстЗапроса(Данные);	
	Таблица = ВыполнитьЗапрос(ТекстЗапроса, ПараметрыЗапроса);	
	Результат = ТаблицаВМассивСтруктур(Таблица);
	
	Возврат Результат;
	
КонецФункции

Функция ПолучитьИдентификаторЗапроса(Данные)
	
	Результат = Данные.queryId;
	
	Если НЕ ЗначениеЗаполнено(Результат) Тогда
		ВызватьИсключение "Не заполнен идентификатор запроса 'queryId'";
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

Функция ПолучитьВнешнийЗапрос(ИдентификаторЗапроса)

	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ ПЕРВЫЕ 1
		|	вз_ВнешниеЗапросы.Ссылка КАК Ссылка,
		|	вз_ВнешниеЗапросы.Вид КАК Вид,
		|	вз_ВнешниеЗапросы.ТекстЗапроса КАК ТекстЗапроса,
		|	вз_ВнешниеЗапросы.ИсполняемыйКод КАК ИсполняемыйКод
		|ИЗ
		|	Справочник.вз_ВнешниеЗапросы КАК вз_ВнешниеЗапросы
		|ГДЕ
		|	вз_ВнешниеЗапросы.Наименование = &ИдентификаторЗапроса
		|	И НЕ вз_ВнешниеЗапросы.ПометкаУдаления";
	
	Запрос.УстановитьПараметр("ИдентификаторЗапроса", ИдентификаторЗапроса);
	
	РезультатЗапроса = Запрос.Выполнить();	
	Если РезультатЗапроса.Пустой() Тогда
		ВызватьИсключение СтрШаблон("Не удалось найти внешний запрос по с идентификатором %1", ИдентификаторЗапроса);
	КонецЕсли;
	
	Выборка = РезультатЗапроса.Выбрать();
	Выборка.Следующий();
	
	Если Выборка.Вид = Перечисления.вз_ВидыВнешнихЗапросов.Запрос
		И НЕ ЗначениеЗаполнено(Выборка.ТекстЗапроса) 
		Тогда
		ВызватьИсключение "Не заполнен текст запроса";
	КонецЕсли;
	
	Если Выборка.Вид = Перечисления.вз_ВидыВнешнихЗапросов.Код
		И НЕ ЗначениеЗаполнено(Выборка.ИсполняемыйКод) 
		Тогда
		ВызватьИсключение "Не заполнен исполняемый код";
	КонецЕсли;
	
	Возврат Выборка.Ссылка;
	
КонецФункции

Функция ПолучитьТекстЗапроса(Данные)
	
	Результат = Данные.queryText;
	
	Если НЕ ЗначениеЗаполнено(Результат) Тогда
		ВызватьИсключение "Не заполнен текст запроса 'queryText'";
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

Функция ПолучитьПараметрыЗапроса(Данные)
	
	ПараметрыЗапроса = Новый Структура;
	
	Для каждого param Из Данные.params Цикл
		ПараметрыЗапроса.Вставить(param.name, ИзвлечьЗначениеИзКонтейнера(param.value));
	КонецЦикла;
	
	Возврат ПараметрыЗапроса;
	
КонецФункции

Процедура ДополнитьПараметрыЗапросаИзСправочника(ВнешнийЗапрос, ПараметрыЗапроса)

	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ЛОЖЬ КАК Проверен,
		|	ПараметрыЗапроса.Внешний КАК Внешний,
		|	ПараметрыЗапроса.Имя КАК Имя,
		|	ПараметрыЗапроса.Значение КАК Значение
		|ИЗ
		|	Справочник.вз_ВнешниеЗапросы КАК ВнешниеЗапросы
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.вз_ВнешниеЗапросы.Параметры КАК ПараметрыЗапроса
		|		ПО ВнешниеЗапросы.Ссылка = ПараметрыЗапроса.Ссылка
		|ГДЕ
		|	ВнешниеЗапросы.Ссылка = &ВнешнийЗапрос";
	
	Запрос.УстановитьПараметр("ВнешнийЗапрос", ВнешнийЗапрос);
	
	ТребуемыеПараметры = Запрос.Выполнить().Выгрузить();
	
	Для каждого Параметр Из ПараметрыЗапроса Цикл
		ТребуемыйПараметр = ТребуемыеПараметры.Найти(Параметр.Ключ, "Имя");
		
		Если ТребуемыйПараметр = Неопределено Тогда
			ВызватьИсключение СтрШаблон("Параметр '%1' не используется", Параметр.Ключ);	
		КонецЕсли;
		
		Если НЕ ТребуемыйПараметр.Внешний Тогда
			ВызватьИсключение СтрШаблон("Параметр '%1' уже установлен в справочнике", Параметр.Ключ);	
		КонецЕсли;
		
		Если ТребуемыйПараметр.Проверен Тогда
			ВызватьИсключение СтрШаблон("Параметр запроса '%1' указан повторно", Параметр.Ключ);	
		КонецЕсли;
		
		ТребуемыйПараметр.Проверен = Истина;
	КонецЦикла;
	
	Для каждого ТребуемыйПараметр Из ТребуемыеПараметры Цикл
		Если ТребуемыйПараметр.Проверен Тогда
			Продолжить;
		КонецЕсли;
		
		Если ТребуемыйПараметр.Внешний Тогда
			ВызватьИсключение СтрШаблон("Не указан необходимый параметр '%1'", ТребуемыйПараметр.Имя);	
		КонецЕсли;
		
		ПараметрыЗапроса.Вставить(ТребуемыйПараметр.Имя, ТребуемыйПараметр.Значение);
		
		ТребуемыйПараметр.Проверен = Истина;		
	КонецЦикла;
	
КонецПроцедуры

Функция ВыполнитьЗапрос(ТекстЗапроса, ПараметрыЗапроса)
	
	Запрос = Новый Запрос;
	Запрос.Текст = ТекстЗапроса;
	
	Для каждого КлючИЗначение Из ПараметрыЗапроса Цикл
		Запрос.УстановитьПараметр(КлючИЗначение.Ключ, КлючИЗначение.Значение);		
	КонецЦикла;	
	
	Возврат Запрос.Выполнить().Выгрузить();
		
КонецФункции

Функция ВыполнитьКодЗапроса(ИсполняемыйКодЗапроса, Параметры)

	УстановитьБезопасныйРежим(Истина);	
	
	Результат = Неопределено;
	Выполнить(ИсполняемыйКодЗапроса);
	
	Возврат Результат;
	
КонецФункции

Функция ТаблицаВМассивСтруктур(Таблица)
	
	// Формируем строку имен колонок
	ИменаКолонок = "";
	КолонкиПеречислений = Новый Массив;
	КолонкиСтрок = Новый Массив;
	КолонкиТипов = Новый Массив;
	
	Для каждого Колонка Из Таблица.Колонки Цикл
		Если ЭтоТипПримитивный(Колонка.ТипЗначения) Тогда
			
		ИначеЕсли ЭтоТипУникальногоИдентификатора(Колонка.ТипЗначения) Тогда	
			КолонкиСтрок.Добавить(Колонка.Имя);
			
		ИначеЕсли ЭтоТипЗначения(Колонка.ТипЗначения) Тогда	
			КолонкиТипов.Добавить(Колонка.Имя);
			
		ИначеЕсли ЭтоТипПеречисление(Колонка.ТипЗначения) Тогда	
			КолонкиПеречислений.Добавить(Колонка.Имя);
			
		Иначе
			Текст = СтрШаблон(
				"В колонке %1 результата запроса использован недопустимый тип значения %2, разрешены: 
				|примитивные типы, перечисления, уникальные идентификаторы", 
				Колонка.Имя,
				Строка(Колонка.ТипЗначения));
				                     
			вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
			ВызватьИсключение Текст;	
		КонецЕсли;
		
		ИменаКолонок = ИменаКолонок + ", " + Колонка.Имя;
	КонецЦикла;
	
	ИменаКолонок = Сред(ИменаКолонок, 3);
	
	// Заполняем результат
	Результат = Новый Массив;
	Для каждого Строка Из Таблица Цикл
		Структура = Новый Структура(ИменаКолонок);
		ЗаполнитьЗначенияСвойств(Структура, Строка);
		
		// Корректируем значения NULL
		Для каждого Колонка Из Таблица.Колонки Цикл
			Если Структура[Колонка.Имя] = Null Тогда
				Структура[Колонка.Имя] = "";	
			КонецЕсли;
		КонецЦикла;
		
		// Переводим несериализуемые значения в строки
		Для каждого ИмяКолонки Из КолонкиСтрок Цикл
			Структура[ИмяКолонки] = Строка(Структура[ИмяКолонки]);	
		КонецЦикла;
		
		// Переводим несериализуемые значения в строки
		Для каждого ИмяКолонки Из КолонкиТипов Цикл
			Структура[ИмяКолонки] = вз_ВнешниеЗапросыПовтИсп.ПолучитьПредставлениеТипа(Структура[ИмяКолонки]);	
		КонецЦикла;
		
		// Корректируем значения перечислений
		Для каждого ИмяКолонки Из КолонкиПеречислений Цикл
			Структура[ИмяКолонки] = вз_ВнешниеЗапросыПовтИсп.ПолучитьИмяЭлементаПеречисленияПоЗначению(Структура[ИмяКолонки]);	
		КонецЦикла;
		
		Результат.Добавить(Структура);		
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти

#Область РаботаСТипами

Функция МассивПримитивныхТипов()

	МассивТипов = Новый Массив;
	МассивТипов.Добавить(Тип("Null"));
	МассивТипов.Добавить(Тип("Булево"));
	МассивТипов.Добавить(Тип("Строка"));
	МассивТипов.Добавить(Тип("Число"));
	МассивТипов.Добавить(Тип("Дата"));
	
	Возврат МассивТипов;
	
КонецФункции

Функция ЭтоТипПримитивный(ОписаниеТипов)

	МассивТипов = МассивПримитивныхТипов();
	
	Для каждого Тип Из ОписаниеТипов.Типы() Цикл
		Если МассивТипов.Найти(Тип) = Неопределено Тогда
			Возврат Ложь;	
		КонецЕсли;	
	КонецЦикла;
	
	Возврат Истина;
	
КонецФункции

Функция ЭтоТипУникальногоИдентификатора(ОписаниеТипов)

	МассивТипов = Новый Массив;
	МассивТипов.Добавить(Тип("Null"));
	МассивТипов.Добавить(Тип("УникальныйИдентификатор"));
	
	Для каждого Тип Из ОписаниеТипов.Типы() Цикл
		Если МассивТипов.Найти(Тип) = Неопределено Тогда
			Возврат Ложь;	
		КонецЕсли;	
	КонецЦикла;
	
	Возврат Истина;
	
КонецФункции

Функция ЭтоТипЗначения(ОписаниеТипов)

	МассивТипов = Новый Массив;
	МассивТипов.Добавить(Тип("Null"));
	МассивТипов.Добавить(Тип("Тип"));
	
	Для каждого Тип Из ОписаниеТипов.Типы() Цикл
		Если МассивТипов.Найти(Тип) = Неопределено Тогда
			Возврат Ложь;	
		КонецЕсли;	
	КонецЦикла;
	
	Возврат Истина;
	
КонецФункции

Функция ЭтоТипПеречисление(ОписаниеТипов)
	
	Для каждого Тип Из ОписаниеТипов.Типы() Цикл
		Если НЕ Тип("Null") = Тип 
			И НЕ Перечисления.ТипВсеСсылки().СодержитТип(Тип) 
			Тогда
			Возврат Ложь;			
		КонецЕсли;	
	КонецЦикла;
	
	Возврат Истина;
		
КонецФункции

#КонецОбласти

#Область Сериализация

Функция ИзвлечьЗначениеИзКонтейнера(Контейнер)
	
	Значение = Неопределено;
	Если ТипЗнч(Контейнер) = Тип("Массив") Тогда
		Значение = Новый Массив();
		Для каждого position Из Контейнер Цикл
			Значение.Добавить(ИзвлечьЗначениеИзКонтейнера(position));	
		КонецЦикла;
		
	ИначеЕсли Контейнер.type = "bool" Тогда
		Значение = XMLЗначение(Тип("Булево"), Контейнер.value);	
		
	ИначеЕсли Контейнер.type = "string" Тогда
		Значение = XMLЗначение(Тип("Строка"), Контейнер.value);
		
	ИначеЕсли Контейнер.type = "double" Тогда
		Значение = XMLЗначение(Тип("Число"), Контейнер.value);
		
	ИначеЕсли Контейнер.type = "date" Тогда
		Значение = XMLЗначение(Тип("Дата"), Контейнер.value);
		
	ИначеЕсли Контейнер.type = "ref" Тогда
		Значение = ИзвлечьСсылкуИзКонтейнера(Контейнер);
		
	Иначе
		Текст = СтрШаблон("Некорректный тип значения %1", Контейнер.type);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуИзКонтейнера(Контейнер)
	
	Менеджер = ОбщегоНазначения.МенеджерОбъектаПоПолномуИмени(Контейнер.objectType);
		
	Значение = Неопределено;
	Если Контейнер.serchingMethod = "reference" Тогда
		Значение = ИзвлечьСсылкуПоискПоСсылке(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "reference-code" Тогда
		Значение = ИзвлечьСсылкуПоискПоСсылкеКоду(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "reference-code-name" Тогда
		Значение = ИзвлечьСсылкуПоискПоСсылкеКодуИмени(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "code" Тогда
		Значение = ИзвлечьСсылкуПоискПоКоду(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "name" Тогда
		Значение = ИзвлечьСсылкуПоискПоИмени(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "reference-number-date" Тогда
		Значение = ИзвлечьСсылкуПоискПоСсылкаНомерДата(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "number-date" Тогда
		Значение = ИзвлечьСсылкуПоискПоНомерДата(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "predefinedName" Тогда
		Значение = ИзвлечьСсылкуПоискПоПредопределенномуИмени(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "custom" Тогда
		Значение = ИзвлечьСсылкуПоискПроизвольный(Менеджер, Контейнер);
		
	ИначеЕсли Контейнер.serchingMethod = "reference-custom" Тогда
		Значение = ИзвлечьСсылкуПоискПоСсылкеПроизвольный(Менеджер, Контейнер);	
		
	Иначе
		Текст = СтрШаблон("Не корректный метод поиска ссылки %1", Контейнер.serchingMethod);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;			
	КонецЕсли;
	
	Возврат Значение;
		
КонецФункции

Функция ИзвлечьСсылкуПоискПоСсылке(Менеджер, Контейнер)

	Значение = вз_ВнешниеЗапросы.ПолучитьСсылку(Менеджер, Контейнер.Ref);
		
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 по ссылке %2", Контейнер.objectType, Контейнер.Ref);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоСсылкеКоду(Менеджер, Контейнер)

	Значение = вз_ВнешниеЗапросы.ПолучитьСсылку(Менеджер, Контейнер.Ref);		
		
	Если НЕ ЗначениеЗаполнено(Значение) Тогда
		Значение = Менеджер.НайтиПоКоду(Контейнер.Code);
	КонецЕсли;
	
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон(
			"Не удалось найти объект %1 по ссылке %2 и коду %3", 
			Контейнер.objectType, 
			Контейнер.Ref, 
			Контейнер.Code);
			
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоСсылкеКодуИмени(Менеджер, Контейнер)

	Значение = вз_ВнешниеЗапросы.ПолучитьСсылку(Менеджер, Контейнер.Ref);		
		
	Если НЕ ЗначениеЗаполнено(Значение) Тогда
		Значение = Менеджер.НайтиПоКоду(Контейнер.Code);
	КонецЕсли;
	
	Если НЕ ЗначениеЗаполнено(Значение) Тогда
		Значение = Менеджер.НайтиПоНаименованию(Контейнер.Name, Истина);
	КонецЕсли;
	
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 по ссылке %2, коду %3 и наименованию %4", 
			Контейнер.objectType, 
			Контейнер.Ref, 
			Контейнер.Code, 
			Контейнер.Name);
			
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоКоду(Менеджер, Контейнер)

	Значение = Менеджер.НайтиПоКоду(Контейнер.Code);
		
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 коду %2", Контейнер.objectType, Контейнер.Code);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоИмени(Менеджер, Контейнер)

	Значение = Менеджер.НайтиПоНаименованию(Контейнер.Name, Истина);
		
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 по наименованию %2", Контейнер.objectType, Контейнер.Name);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоСсылкаНомерДата(Менеджер, Контейнер)

	Значение = вз_ВнешниеЗапросы.ПолучитьСсылку(Менеджер, Контейнер.Ref);		
		
	Если НЕ ЗначениеЗаполнено(Значение) Тогда
		Значение = Менеджер.НайтиПоНомеру(Контейнер.Number, XMLЗначение(Тип("Дата"), Контейнер.Date));
	КонецЕсли;
	
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 по ссылке %2, а затем номеру %3 и дате %4", 
			Контейнер.objectType, 
			Контейнер.Ref, 
			Контейнер.Number, 
			XMLЗначение(Тип("Дата"), 
			Контейнер.Date));
			
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоНомерДата(Менеджер, Контейнер)

	Значение = Менеджер.НайтиПоНомеру(Контейнер.Number, XMLЗначение(Тип("Дата"), Контейнер.Date));
		
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 по номеру %2 и дате %3", 
			Контейнер.objectType, 
			Контейнер.Number, 
			XMLЗначение(Тип("Дата"), Контейнер.Date));
			
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоПредопределенномуИмени(Менеджер, Контейнер)

	Значение = Менеджер[Контейнер.PredefinedName];
	
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон(
			"Не удалось найти объект %1 по предопределенному имени %2", 
			Контейнер.objectType, 
			Контейнер.PredefinedName);
			
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПроизвольный(Менеджер, Контейнер)

	Значение = ВыполнитьКодПроизвольногоПоиска(Контейнер.CustomCode, Контейнер.CustomParams);
	
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 произвольным поиском", Контейнер.objectType);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ИзвлечьСсылкуПоискПоСсылкеПроизвольный(Менеджер, Контейнер)
	
	Значение = вз_ВнешниеЗапросы.ПолучитьСсылку(Менеджер, Контейнер.Ref);		
	
	Если НЕ ЗначениеЗаполнено(Значение) Тогда
		Значение = ВыполнитьКодПроизвольногоПоиска(Контейнер.CustomCode, Контейнер.CustomParams);
	КонецЕсли;
	
	Если Контейнер.giveSearchError И НЕ ЗначениеЗаполнено(Значение) Тогда
		Текст = СтрШаблон("Не удалось найти объект %1 произвольным поиском", Контейнер.objectType);
		вз_ВнешниеЗапросыСлужебный.ЗаписатьВЖурнал(Текст, УровеньЖурналаРегистрации.Ошибка, "Входящий");
		ВызватьИсключение Текст;
	КонецЕсли;
	
	Возврат Значение;
		
КонецФункции

Функция ВыполнитьКодПроизвольногоПоиска(ВыполняемыйКодПоиска, Параметры)

	УстановитьБезопасныйРежим(Истина);
	
	Значение = Неопределено;
	Выполнить(ВыполняемыйКодПоиска);
	
	Возврат Значение;
	
КонецФункции

#КонецОбласти