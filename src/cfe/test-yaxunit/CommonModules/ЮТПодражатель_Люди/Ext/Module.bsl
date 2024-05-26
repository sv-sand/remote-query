﻿//©///////////////////////////////////////////////////////////////////////////©//
//
//  Copyright 2021-2023 BIA-Technologies Limited Liability Company
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//©///////////////////////////////////////////////////////////////////////////©//

#Область ПрограммныйИнтерфейс

// Возвращает случайное имя
//
// Параметры:
//  Пол - Строка - см. ЮТПодражатель_Люди.ПолЧеловека
//
// Возвращаемое значение:
//	Строка
Функция Имя(Пол = Неопределено) Экспорт

	ПолЧеловека = ОпределитьПолЧеловекаИзПараметра(Пол);

	Если ПолЧеловека = ПолЧеловека().Мужской  Тогда
		Словарь = СловарьМужскиеИмена();
	ИначеЕсли ПолЧеловека = ПолЧеловека().Женский Тогда
		Словарь = СловарьЖенскиеИмена();
	КонецЕсли;

	Возврат ЮТПодражательСлужебный.СлучайноеЗначениеИзСловаря(Словарь);

КонецФункции

// Возвращает случайную фамилию
//
// Параметры:
//  Пол - Строка - см. ЮТПодражатель_Люди.ПолЧеловека
//
// Возвращаемое значение:
//	Строка
Функция Фамилия(Пол = Неопределено) Экспорт

	ПолЧеловека = ОпределитьПолЧеловекаИзПараметра(Пол);

	Если ПолЧеловека = ПолЧеловека().Мужской  Тогда
		Словарь = СловарьМужскиеФамилии();
	ИначеЕсли ПолЧеловека = ПолЧеловека().Женский Тогда
		Словарь = СловарьЖенскиеФамилии();
	КонецЕсли;

	Возврат ЮТПодражательСлужебный.СлучайноеЗначениеИзСловаря(Словарь);

КонецФункции

// Возвращает случайное отчество
//
// Параметры:
//  Пол - Строка - см. ЮТПодражатель_Люди.ПолЧеловека
//
// Возвращаемое значение:
//	Строка
Функция Отчество(Пол = Неопределено) Экспорт

	ПолЧеловека = ОпределитьПолЧеловекаИзПараметра(Пол);

	Если ПолЧеловека = ПолЧеловека().Мужской  Тогда
		Словарь = СловарьМужскиеОтчества();
	ИначеЕсли ПолЧеловека = ПолЧеловека().Женский Тогда
		Словарь = СловарьЖенскиеОтчества();
	КонецЕсли;

	Возврат ЮТПодражательСлужебный.СлучайноеЗначениеИзСловаря(Словарь);

КонецФункции

// Возвращает случайное отчество
//
// Параметры:
//  Пол - Строка - см. ЮТПодражатель_Люди.ПолЧеловека
//
// Возвращаемое значение:
//	Строка
Функция ФИО(Пол = Неопределено) Экспорт

	ПолЧеловека = ОпределитьПолЧеловекаИзПараметра(Пол);

	Возврат СтрШаблон(
		"%1 %2 %3",
		Фамилия(ПолЧеловека),
		Имя(ПолЧеловека),
		Отчество(ПолЧеловека)
	);

КонецФункции

// Формирует случаный ИНН физического лица
//
// Возвращаемое значение:
// 	Строка
Функция ИНН() Экспорт
	Возврат ЮТТестовыеДанные.Подражатель().Компании().ИНН(, Истина);
КонецФункции

// Формирует случаный СНИЛС.
// https://ru.wikipedia.org/wiki/Контрольное_число
// Возвращаемое значение:
//  Строка
Функция СНИЛС() Экспорт
	ЧастиСнилс = Новый Массив();
	ЧастиСнилс.Добавить(Формат(ЮТТестовыеДанные.СлучайноеЧисло(100, 999), "ЧЦ=3; ЧВН=;"));
	ЧастиСнилс.Добавить(Формат(ЮТТестовыеДанные.СлучайноеЧисло(0, 999), "ЧЦ=3; ЧВН=;"));
	ЧастиСнилс.Добавить(Формат(ЮТТестовыеДанные.СлучайноеЧисло(0, 999), "ЧЦ=3; ЧВН=;"));

	ИтогоСтрокой = СтрСоединить(ЧастиСнилс, "");
	ДлинаОсновнойЧасти = СтрДлина(ИтогоСтрокой);
	Сумма = 0;
	Для Итератор = 0 По 8 Цикл
		Сумма = Сумма + (Число(Сред(ИтогоСтрокой, ДлинаОсновнойЧасти - Итератор, 1)) * (Итератор + 1));
	КонецЦикла;

	ОстатокОтДеления = Сумма % 101;
	КонтрольноеЧисло = ?(ОстатокОтДеления = 100, 0, ОстатокОтДеления);

	Возврат СтрШаблон(
		"%1-%2-%3 %4",
		ЧастиСнилс[0],
		ЧастиСнилс[1],
		ЧастиСнилс[2],
		Формат(КонтрольноеЧисло, "ЧЦ=2; ЧН=00; ЧВН=;")
	);

КонецФункции

#Область ФабрикаПеречислений

Функция ПолЧеловека() Экспорт

	Результат = Новый Структура();
	Результат.Вставить("Мужской", "Мужской");
	Результат.Вставить("Женский", "Женский");
	Возврат Новый ФиксированнаяСтруктура(Результат);

КонецФункции

#КонецОбласти

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ИмяРеализации()
	Возврат "Люди";
КонецФункции

Функция СловарьЖенскиеИмена()
	Возврат ЮТПодражательСлужебный.Словарь(ИмяРеализации(), "ЖенскиеИмена");
КонецФункции
Функция СловарьЖенскиеФамилии()
	Возврат ЮТПодражательСлужебный.Словарь(ИмяРеализации(), "ЖенскиеФамилии");
КонецФункции
Функция СловарьЖенскиеОтчества()
	Возврат ЮТПодражательСлужебный.Словарь(ИмяРеализации(), "ЖенскиеОтчества");
КонецФункции

Функция СловарьМужскиеИмена()
	Возврат ЮТПодражательСлужебный.Словарь(ИмяРеализации(), "МужскиеИмена");
КонецФункции
Функция СловарьМужскиеФамилии()
	Возврат ЮТПодражательСлужебный.Словарь(ИмяРеализации(), "МужскиеФамилии");
КонецФункции
Функция СловарьМужскиеОтчества()
	Возврат ЮТПодражательСлужебный.Словарь(ИмяРеализации(), "МужскиеОтчества");
КонецФункции

Функция ОпределитьПолЧеловекаИзПараметра(Пол)

	Если Пол <> Неопределено Тогда
		Если Не ПолЧеловека().Свойство(Пол) Тогда
			ВызватьИсключение СтрШаблон("Отсутствует реализация словаря для пола: %1", Пол);
		КонецЕсли;
		Возврат Пол;
	КонецЕсли;

	Варианты = ЮТОбщий.ВыгрузитьЗначения(ПолЧеловека(), "Значение");

	Возврат ЮТТестовыеДанные.СлучайноеЗначениеИзСписка(Варианты);
КонецФункции

#КонецОбласти
