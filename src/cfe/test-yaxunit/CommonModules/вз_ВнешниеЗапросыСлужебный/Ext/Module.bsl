﻿
&Вместо("HTTPЗапрос")
Функция ЮТHTTPЗапрос(ПараметрыПодключения, АдресРесурса, ТелоЗапроса)
	
	// Собираем параметры в массив
    ПараметрыМетода = Мокито.МассивПараметров(ПараметрыПодключения, АдресРесурса, ТелоЗапроса);

    // Отправляем данные на анализ  	
    ПрерватьВыполнение = Ложь;
    Результат = Мокито.АнализВызова(вз_ВнешниеЗапросыСлужебный, "HTTPЗапрос", ПараметрыМетода, ПрерватьВыполнение);
                           	
    // Обрабатываем результат анализа
    Если НЕ ПрерватьВыполнение Тогда
        Возврат ПродолжитьВызов(ПараметрыПодключения, АдресРесурса, ТелоЗапроса);
    Иначе
        Возврат Результат;
    КонецЕсли;
	
КонецФункции
