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

#Область СлужебныйПрограммныйИнтерфейс

Функция ВТранзакции() Экспорт
	
	ИмяПараметра = ЮТФабрика.ПараметрыИсполненияТеста().ВТранзакции;
	
	Возврат ЗначениеНастройкиТеста(ИмяПараметра, Ложь);
	
КонецФункции

Функция УдалениеТестовыхДанных() Экспорт
	
	ИмяПараметра = ЮТФабрика.ПараметрыИсполненияТеста().УдалениеТестовыхДанных;
	
	Возврат ЗначениеНастройкиТеста(ИмяПараметра, Ложь);
	
КонецФункции

Функция Перед() Экспорт
	
	ИмяПараметра = ЮТФабрика.ПараметрыИсполненияТеста().Перед;
	
	Возврат ЗначениеНастройкиТеста(ИмяПараметра, "", Истина);
	
КонецФункции

Функция После() Экспорт
	
	ИмяПараметра = ЮТФабрика.ПараметрыИсполненияТеста().После;
	
	Возврат ЗначениеНастройкиТеста(ИмяПараметра, "", Истина);
	
КонецФункции

Функция ЗначениеНастройкиТеста(ИмяНастройки, ЗначениеПоУмолчанию, СтрогийУровеньИсполнения = Ложь) Экспорт
	
	Значение = ЗначениеПоУмолчанию;
	КонтекстИсполнения = ЮТКонтекст.КонтекстИсполнения();
	
	Если СтрогийУровеньИсполнения Тогда
		
		ТекущийКонтекстИсполнения = ЮТКонтекст.КонтекстИсполненияТекущегоУровня();
		
		Если ТекущийКонтекстИсполнения <> Неопределено Тогда
			Значение = ЮТОбщий.ЗначениеСтруктуры(ТекущийКонтекстИсполнения.НастройкиВыполнения, ИмяНастройки, ЗначениеПоУмолчанию);
		КонецЕсли;
		
	ИначеЕсли КонтекстИсполнения.Тест <> Неопределено И КонтекстИсполнения.Тест.НастройкиВыполнения.Свойство(ИмяНастройки) Тогда
		
		Значение = КонтекстИсполнения.Тест.НастройкиВыполнения[ИмяНастройки];
		
	ИначеЕсли КонтекстИсполнения.Набор <> Неопределено И КонтекстИсполнения.Набор.НастройкиВыполнения.Свойство(ИмяНастройки) Тогда
		
		Значение = КонтекстИсполнения.Набор.НастройкиВыполнения[ИмяНастройки];
		
	ИначеЕсли КонтекстИсполнения.Модуль <> Неопределено И КонтекстИсполнения.Модуль.НастройкиВыполнения.Свойство(ИмяНастройки) Тогда
		
		Значение = КонтекстИсполнения.Модуль.НастройкиВыполнения[ИмяНастройки];
		
	Иначе
		
		ГлобальныеНастройки = ЮТКонтекст.ГлобальныеНастройкиВыполнения();
		
		Если ГлобальныеНастройки.Свойство(ИмяНастройки) Тогда
			Значение = ГлобальныеНастройки[ИмяНастройки];
		КонецЕсли;
		
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

#КонецОбласти
